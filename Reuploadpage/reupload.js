$(document).ready(function() {

    $('form.reupload').submit(function(e) {
        e.preventDefault(); // Prevent the form from submitting normally
    

        var formData = new FormData(this);



        $.ajax({
            url: '/reupload',
            type: 'POST',
            data: formData,
            cache: false,
            contentType: false,
            processData: false,
            success: function(response) {
                $('.message.reupload-message').text('File reupload successfullyyyyyyyyyyyyyyyy.');
            },
            error: function(xhr, status, error) {
                console.log('File reupload failed.');
                $('.message.reupload-message').text('File didn\'t upload successfully.');
            }
        });
    });
});

function goToOwn() {
    window.location.href = "/update-access";  
    }	
    
function goToUpload() {
    window.location.href = "/upload";
    }
    
function goToHome() {
    window.location.href = "/";
    }