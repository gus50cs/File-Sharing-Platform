package main

import (
	"sort"
	"encoding/json"
	"github.com/hyperledger/fabric-gateway/pkg/client"
	"os"
	"time"
	"fmt"
	"strconv"
	//"strings"
	"web/scripts/check"
	"web/scripts/handelrs"
	"web/scripts/grcp"
	"web/scripts/session"
	"web/scripts/smartfunc"
	"net/http"
	"strings"
	"github.com/gin-gonic/gin"
	"github.com/gin-contrib/sessions"
	"github.com/gin-contrib/sessions/cookie"
	"html/template"
    _ "github.com/go-sql-driver/mysql"
)

type Asset struct {
	DocumentID string
	Owner      string
	DocumentCID		string
	Timestamp 	string
	IsChecked bool
	Reupload string
}


type AssetOwner struct {
	DocumentID string
	Owner      string
	DocumentCID		[]string
	Timestamp 	[]string
	AccessList []string
	Reupload string
	CheckList []string
	WaitingList []string
}

type Document struct {
	ID          int
	UserID      string
	DocumentID  string
	OwnerID     string
	DocumentCID string
	CreatedAt   string
	IsChecked    bool
}	


const (
	mspID        = "ship1MSP"
	cryptoPath   = "/home/kevin/thesis/organizations/ship1"
	certPath     = cryptoPath + "/users/user/msp/signcerts/cert.pem"
	keyPath      = cryptoPath + "/users/user/msp/keystore/"
	tlsCertPath  = cryptoPath + "/peers/peer1/tls-msp/tlscacerts/ca.crt"
	peerEndpoint = "localhost:1012"
	gatewayPeer  = "peer1.ship1"
)

func main() {

	//var username string

	// The gRPC client connection should be shared by all Gateway connections to this endpoint
	clientConnection := connection.NewGrpcConnection(tlsCertPath, gatewayPeer, peerEndpoint)
	defer clientConnection.Close()

	id := connection.NewIdentity(certPath, mspID)
	sign := connection.NewSign(keyPath)

	// Create a Gateway connection for a specific client identity
	gw, err := client.Connect(
		id,
		client.WithSign(sign),
		client.WithClientConnection(clientConnection),
		// Default timeouts for different gRPC calls
		client.WithEvaluateTimeout(5*time.Second),
		client.WithEndorseTimeout(15*time.Second),
		client.WithSubmitTimeout(5*time.Second),
		client.WithCommitStatusTimeout(1*time.Minute),
	)
	if err != nil {
		panic(err)
	}
	defer gw.Close()

	// Override default values for chaincode and channel name as they may differ in testing contexts.
	chaincodeName := "basic"
	if ccname := os.Getenv("CHAINCODE_NAME"); ccname != "" {
		chaincodeName = ccname
	}

	channelName := "connect.channel"
	if cname := os.Getenv("CHANNEL_NAME"); cname != "" {
		channelName = cname
	}

	network := gw.GetNetwork(channelName)
	contract := network.GetContract(chaincodeName)



	r := gin.Default()

	store := cookie.NewStore([]byte("secret")) // Change "secret" to your desired session secret
	store.Options(sessions.Options{
		Path:     "/",
		MaxAge:   0, // Set MaxAge to 0 to generate a new session ID on each login
		HttpOnly: true,
	})
	r.Use(sessions.Sessions("session", store))


	// Serve the frontend files
	r.Static("/static", ".")
	r.SetHTMLTemplate(template.Must(template.New("").Funcs(template.FuncMap{
		"join": joinStrings,
	}).ParseFiles("upload.html", "login.html", "Ownfiles.html", "Checkfiles.html", "Home.html", "account.html", "Reuploaded.html")))

	// Middleware to clear session on login page access
	r.Use(func(c *gin.Context) {
		if c.Request.URL.Path == "/login" {
			session := sessions.Default(c)
			session.Clear()
			session.Save()
		}
		c.Next()
	})

	r.GET("/login", func(c *gin.Context) {
		session := sessions.Default(c)
		if session.Get("authenticated") == true {
			c.Redirect(http.StatusFound, "/")
			return
		}
		
		c.HTML(http.StatusOK, "login.html", gin.H{})
	})

	r.POST("/login",func(c *gin.Context) {
		username, err := session.LoginHandler(c)
		if err != true {
			fmt.Println(err)
		}

		// Store the username in the session
		session := sessions.Default(c)
		session.Set("username", username)
		session.Save()
		c.Redirect(http.StatusFound, "/")
	})
	

	r.GET("/saveCheckedFile", func(c *gin.Context) {
		// Retrieve the assets
		session := sessions.Default(c)
		username := session.Get("username")
		assets, err := smartfunc.GetAssetsWithCID(contract, username.(string))
		if err != nil {
			fmt.Errorf("failed to parse JSON result: %w", err)
		}
	
		checkedFiles := check.RetrieveChecked(username.(string))
	
		uncheckedAssets := make([]*Asset, 0)
		checkedAssets := make([]*Asset, 0)

		// Find the latest asset for each DocumentID and Owner
		for _, asset := range assets {
			exclude := false
			if asset.Reupload == "false" {
				for _, checkedFile := range checkedFiles {
					if asset.Timestamp == checkedFile.Timestamp {
						exclude = true
						break
					}
				}
			
				if exclude {
					newAsset := &Asset{
						DocumentID:  asset.DocumentID,
						Owner:       asset.Owner,
						DocumentCID: asset.DocumentCID,
						Timestamp:   asset.Timestamp,
						Reupload: asset.Reupload,
						IsChecked: true,
					}
					checkedAssets = append(checkedAssets, newAsset)
				} else {
					newAsset := &Asset{
						DocumentID:  asset.DocumentID,
						Owner:       asset.Owner,
						DocumentCID: asset.DocumentCID,
						Timestamp: asset.Timestamp,
					}
	
					uncheckedAssets = append(uncheckedAssets, newAsset)
				}

			}
		}

	
		c.HTML(http.StatusOK, "Checkfiles.html", gin.H{
			"Assets": uncheckedAssets,
			"CheckedFiles": checkedAssets,
		})
	})
	
	
	




	r.POST("/saveCheckedFile", func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username")
		//fmt.Println(username)
		timestamp := c.PostForm("timestamp")
		isChecked := c.PostForm("isChecked")
		isCheckedBool, err := strconv.ParseBool(isChecked)
		if err != nil {
			fmt.Println(err)
		}

		isReuploaded := false

		check.Insert(username.(string), timestamp, isCheckedBool, isReuploaded)
	})
	
	

	r.GET("/upload", func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username").(string)
		users, err := check.GetUsernames(username)
		if err != nil {
			fmt.Println("Failed to connect to MySQL:", err)
		}

		c.HTML(http.StatusOK, "upload.html", gin.H{
			"Username": username,
			"Users": users,
		})
	})

	r.POST("/upload", func(c *gin.Context) {
	
		documentID := c.PostForm("documentID")
  		owner := c.PostForm("owner")
  		accessList := c.PostFormArray("accessListItem")
		accessList = removeDuplicates(accessList)
		reuploadStr := c.PostForm("reuploadCheckbox")
		reupload := reuploadStr == "on" // Convert the string value to a boolean 
		accessListStr := strings.Join(accessList, ", ")
		cid, error := handelrs.UploadHandler(c)
		if error != true {
			fmt.Println(error)
		}
		reuploadString := strconv.FormatBool(reupload)
		
		smartfunc.CreateAsset(contract, documentID, cid, owner, accessListStr,reuploadString)
		c.String(http.StatusOK, "File uploaded successfully")

	})
	r.GET("/download/:cid", func(c *gin.Context) {
		handelrs.DownloadHandler(c)
	})

	r.GET("/", func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username")
		if session.Get("authenticated") != true {
			c.Redirect(http.StatusFound, "/login")
			return
		}
		if username == nil {
			c.Redirect(http.StatusFound, "/login")
			return
		}

		c.HTML(http.StatusOK, "Home.html", gin.H{})
	})
	
			
	r.GET("/update-access", func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username")
				
		assetsowner, err := smartfunc.GetOwnerWithCID(contract, username.(string))
		if err != nil {
				fmt.Errorf("failed to parse JSON result: %w", err)
		}
				
		latestAssets := make(map[string]AssetOwner)
	
		for _, asset := range assetsowner {
		assetKey := asset.DocumentID + "-" + strings.Join(asset.AccessList, ",")
		existingAsset, exists := latestAssets[assetKey]
			
		if !exists {
			latestAssets[assetKey] = AssetOwner{
				DocumentID:  asset.DocumentID,
				Owner:       asset.Owner,
				AccessList:  asset.AccessList,
				Reupload : asset.Reupload,
				DocumentCID: []string{asset.DocumentCID},
           		Timestamp:   []string{asset.Timestamp},
			}
				

		} else {
			existingAsset.DocumentCID = append(existingAsset.DocumentCID, asset.DocumentCID)
        	existingAsset.Timestamp = append(existingAsset.Timestamp, asset.Timestamp)
        	latestAssets[assetKey] = existingAsset
			}
		}
		checked := make([]AssetOwner, 0, len(latestAssets))
		reuploaded := make([]AssetOwner, 0, len(latestAssets))
		for _, asset := range latestAssets {
			if asset.Reupload == "true" {
				for _, access := range asset.AccessList{
					foundMatch := false
					checkedFiles := check.RetrieveUploaded(access)
					for _, temp := range asset.Timestamp {
						for _, checkedFile := range checkedFiles {
							if temp == checkedFile.Timestamp {
								asset.CheckList = append(asset.CheckList, access)
								foundMatch = true
							}
										
									
						}
					}
					if !foundMatch {
						asset.WaitingList = append (asset.WaitingList, access)
					}
							
				}
				exists := false
				for _, a := range reuploaded {
					if a.DocumentID == asset.DocumentID {
						exists = true
						break
					}
				}
							
					if !exists {
								reuploaded = append(reuploaded, asset)
							}
								
			} else {
				for _, access := range asset.AccessList{
					foundMatch := false
					checkedFiles := check.RetrieveChecked(access)
					for _, checkedFile := range checkedFiles {
						for _, temp := range asset.Timestamp {
							if temp == checkedFile.Timestamp {
								asset.CheckList = append(asset.CheckList, access)
								foundMatch = true
								break
							} 
						}	
					}
					if !foundMatch {
						asset.WaitingList = append(asset.WaitingList, access)
					}
					}	
				checked = append(checked, asset)
					    
				}
		}


		for i := range reuploaded {
			sortTimestampsAndCID(&reuploaded[i])
		}

		
		
		c.HTML(http.StatusOK, "Ownfiles.html", gin.H{
			"CheckedAssets": checked,
			"ReuploadedAssets": reuploaded,
					})
			})
		
	
	
	
	
	

	r.POST("/update-access", func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username")	
		assetsowner, err := smartfunc.GetOwnerWithCID(contract, username.(string))
		if err != nil {
				fmt.Errorf("failed to parse JSON result: %w", err)
		}	
		documentID := c.PostForm("documentID")
		newaccessListStr := c.PostForm("accessList")
		documentCID := c.PostForm("documentCID")
		var oldaccessList []string
		//fmt.Println( documentID, accessListStr, documentCID)
		for _, asset := range assetsowner {
			if asset.DocumentCID == documentCID{
				oldaccessList = asset.AccessList
			}
		}	
		for _, asset := range assetsowner {
			if asset.DocumentID == documentID {
			 if arraysAreEqual(asset.AccessList, oldaccessList) {
				smartfunc.UpdateAccess(contract, newaccessListStr, documentID, username.(string), asset.DocumentCID)
			 }	
			}
		}
		c.String(http.StatusOK, "Access list updated successfully")
	})

	r.POST("/delete", func(c *gin.Context) {
		documentID := c.PostForm("documentID")
		owner := c.PostForm("ownerID")
		documentCID := c.PostForm("documentCID")

		smartfunc.DeleteAsset(contract, documentID, owner, documentCID)
		c.String(http.StatusOK, "File deleted successfully")
		
	})



	r.GET("/logout", func(c *gin.Context) {
		session.LogoutHandler(c)
	})

	


	r.GET("account", func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username")
		c.HTML(http.StatusOK, "account.html", gin.H{
			"username": username,
		})
	})

	r.POST("account", func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username")
		password := c.PostForm("password")
		check.ChangeUserPassword(username.(string), password)
	})


	  r.POST("reupload", func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username")
		documentID := c.PostForm("documentID")
		owner := c.PostForm("owner")
		documentCID := c.PostForm("documentCID")
		isChecked := false
		isReuploaded := true
		timestamp := time.Now().Format("15:04:05 02-01-2006")
		check.Insert(username.(string), timestamp, isChecked, isReuploaded)
		
		// Process the file upload
		cid, error := handelrs.UploadHandler(c)
		if error != true {
			fmt.Println(error)
		}
		result := smartfunc.ReadAsset(contract, owner, documentID, documentCID)
		var parsedResult map[string]interface{}
		if err := json.Unmarshal([]byte(result), &parsedResult); err != nil {
    		panic(fmt.Errorf("failed to parse result: %w", err))
		}

		accessList := parsedResult["AccessList"].([]interface{})
		accessListStrings := make([]string, len(accessList))
		for i, item := range accessList {
    		accessListStrings[i] = item.(string)
		}

		accessListString := strings.Join(accessListStrings, ", ")
		reuploadString := strconv.FormatBool(isReuploaded)
		fmt.Println(documentID, cid, owner, accessListString, reuploadString)
		smartfunc.CreateAsset(contract, documentID, cid, owner, accessListString, reuploadString)
		
		c.String(http.StatusOK, "File reuploaded successfully")
		
	  })
	
	  r.GET("reupload", func(c *gin.Context) {
		// Retrieve the assets
		session := sessions.Default(c)
		username := session.Get("username")
		assets, err := smartfunc.GetAssetsWithCID(contract, username.(string))
		if err != nil {
			fmt.Errorf("failed to parse JSON result: %w", err)
		}
		
		reuploadedFiles := check.RetrieveUploaded(username.(string))
		
		unreuploadedAssets := make([]*Asset, 0)
		reuploadedAssets := make([]*Asset, 0)
		latestAssets := make(map[string]*Asset) // Map to track the latest asset for each DocumentID and Owner
		// Find the latest asset for each DocumentID and Owner
		for _, asset := range assets {
			if asset.Reupload == "true"{
				
				assetKey := asset.DocumentID + asset.Owner
				latestAsset, found := latestAssets[assetKey]
				if !found || compareTimestamps(asset.Timestamp, latestAsset.Timestamp) > 0 {
					newAsset := &Asset{
						DocumentID:  asset.DocumentID,
						Owner:       asset.Owner,
						DocumentCID: asset.DocumentCID,
						Timestamp:   asset.Timestamp,
						Reupload:    asset.Reupload,
					}
					latestAssets[assetKey] = newAsset
				}
			} 
		}	
		// Append the latest assets to the filtered assets
		for _, asset := range assets {
			//fmt.Println(asset)
			exclude := false
			if asset.Reupload == "true"{
				assetKey := asset.DocumentID + asset.Owner
				for _, reuploadedFile := range reuploadedFiles {
					if asset.Timestamp == reuploadedFile.Timestamp{
						exclude = true
						break
					} 
				}
			

			if exclude {
				newAsset := &Asset{
					DocumentID:  asset.DocumentID,
					Owner:       asset.Owner,
					DocumentCID: latestAssets[assetKey].DocumentCID,
					Timestamp:   latestAssets[assetKey].Timestamp,
					Reupload:    asset.Reupload,
				}
				
				reuploadedAssets = append(reuploadedAssets, newAsset)
			} else {
						newAsset := &Asset{
							DocumentID:  asset.DocumentID,
							Owner:       asset.Owner,
							DocumentCID: latestAssets[assetKey].DocumentCID,
							Timestamp:   latestAssets[assetKey].Timestamp,
							Reupload:    asset.Reupload,
						}
						unreuploadedAssets = append(unreuploadedAssets, newAsset)	
					
				}
				
			
		}
	}
	for i := 0; i < len(unreuploadedAssets); i++ {
		unreuploaded := unreuploadedAssets[i]
		for _, reuploaded := range reuploadedAssets{
			if unreuploaded.DocumentID == reuploaded.DocumentID && unreuploaded.Owner == reuploaded.Owner {
				unreuploadedAssets = append(unreuploadedAssets[:i], unreuploadedAssets[i+1:]...)
				i--
				break
			}

		}
	}

	uniqueAssets := make(map[string]*Asset)

	for _, unreuploaded := range unreuploadedAssets {
		// Generate a unique key for each asset based on DocumentID and Owner
		assetKey := unreuploaded.DocumentID + unreuploaded.Owner
	
		// Check if the asset with this key already exists in the map
		if _, exists := uniqueAssets[assetKey]; !exists {
			// If it doesn't exist, add it to the map
			uniqueAssets[assetKey] = unreuploaded
		}
	}
	
	// Convert the map back to a slice of unique assets
	filteredUnreuploadedAssets := make([]*Asset, 0, len(uniqueAssets))
	for _, asset := range uniqueAssets {
		filteredUnreuploadedAssets = append(filteredUnreuploadedAssets, asset)
	}


		c.HTML(http.StatusOK, "Reuploaded.html", gin.H{
			"Unreuploaded": filteredUnreuploadedAssets,
			"Reuploaded" : reuploadedAssets,
		})
	})


	//smartfunc.DeleteAsset(contract, "", "")
	// /smartfunc.AllAsset(contract)
	r.Run(":8080")

}


func contains(files []Document, asset Asset) bool {
	for _, file := range files {
		if file.DocumentCID == asset.DocumentCID &&
			file.DocumentID == asset.DocumentID &&
			file.OwnerID == asset.Owner {
			return true
		}
	}
	return false
}


func joinStrings(slice []string, separator string) string {
	return strings.Join(slice, separator)
}

func compareTimestamps(ts1, ts2 string) int {
	format := "15:04:05 02-01-2006" // Time format for parsing the timestamps

	t1, err := time.Parse(format, ts1)
	if err != nil {
		fmt.Println("Invalid timestamp:", ts1)
		return 1 // Return a positive value if ts1 is invalid
	}

	t2, err := time.Parse(format, ts2)
	if err != nil {
		fmt.Println("Invalid timestamp:", ts2)
		return -1 // Return a negative value if ts2 is invalid
	}

	result := t1.Compare(t2)
	return result
}

func removeDuplicates(arr []string) []string {
    uniqueMap := make(map[string]bool)
    uniqueSlice := []string{}

    for _, elem := range arr {
        if !uniqueMap[elem] {
            uniqueMap[elem] = true
            uniqueSlice = append(uniqueSlice, elem)
        }
    }

    return uniqueSlice
}

func sortTimestampsAndCID(doc *AssetOwner) {
	sortedData := make([]struct {
		Timestamp string
		DocumentCID string
	}, len(doc.Timestamp))

	// Populate the sortedData slice
	for i := range doc.Timestamp {
		sortedData[i] = struct {
			Timestamp   string
			DocumentCID string
		}{doc.Timestamp[i], doc.DocumentCID[i]}
	}

	// Sort the sortedData slice based on Timestamps in descending order
	sort.SliceStable(sortedData, func(i, j int) bool {
		timeI, _ := time.Parse("15:04:05 02-01-2006", sortedData[i].Timestamp)
		timeJ, _ := time.Parse("15:04:05 02-01-2006", sortedData[j].Timestamp)
		return timeI.After(timeJ) // Compare in descending order
	})

	// Update the Timestamps and Names fields based on sortedData
	for i, data := range sortedData {
		doc.Timestamp[i] = data.Timestamp
		doc.DocumentCID[i] = data.DocumentCID
	}
}

func arraysAreEqual(arr1, arr2 []string) bool {
    // Check if the arrays have the same length
    if len(arr1) != len(arr2) {
        return false
    }

    // Create a map to count the occurrences of each element in arr1
    countMap := make(map[string]int)

    // Count elements in arr1
    for _, str := range arr1 {
        countMap[str]++
    }

    // Decrement the count for each element in arr2
    for _, str := range arr2 {
        countMap[str]--
    }

    // If all elements have a count of zero, the arrays have the same elements
    for _, count := range countMap {
        if count != 0 {
            return false
        }
    }

    return true
}