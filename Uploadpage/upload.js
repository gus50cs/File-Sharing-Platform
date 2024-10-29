$(document).ready(function() {
    $('form.upload').submit(function(e) {
        e.preventDefault(); // Prevent the form from submitting normally

        var formData = new FormData(this);
        var reuploadCheckbox = $('#reuploadCheckbox').is(':checked');

        var accessListValues = $('#accessListInput').val().split(','); // Split the input value into an array
        accessListValues.forEach(function(value) {
            formData.append('accessListItem', value.trim()); // Append each value to the form data
        });

        formData.append('reuploadCheckbox', reuploadCheckbox);

        $.ajax({
            url: '/upload',
            type: 'POST',
            data: formData,
            cache: false,
            contentType: false,
            processData: false,
            success: function(response) {
                $('.message.upload-message').text('File uploaded successfully.');
                $('form.upload input[type="text"]').val(''); // Clear input fields
                $('form.upload input[type="file"]').val(''); // Clear file input field
            },
            error: function(xhr, status, error) {
                $('.message.upload-message').text('File didn\'t upload successfully.');
            }
        });
    });
});

function goToOwn() {
    window.location.href = "/update-access";
}

function goToFiles() {
    window.location.href = "/saveCheckedFile";
}

function goToHome() {
    window.location.href = "/";
}