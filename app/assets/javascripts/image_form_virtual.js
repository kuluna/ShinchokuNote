$(document).on('turbolinks:load', function(){
    // Max size of image(3MB)
    var MAX_IMAGE_SIZE = 1024 * 1024 * 1.5;  // IE doesn't allow const
    
    var $postform = $('#new_post');
    var $postform_submit = $('#new_post input[type=submit]')
    var $virtualform = $('#image_form_virtual');
    var $realform = $('#image_form_hidden');
    var $clickandselect = $('#image_form_click_and_select');
    var $preview = $('#image_form_preview');
    var $editconfirm = $('#edit_confirm_button');
    var $canvas = $('#image_edit_canvas');
    var $canvas_ui = $('#image_edit_ui_canvas');
    var $imageeditmodal = $('#image_edit_modal');
    var imagecount = 0;
    var $pendingimages = {};

    function disableEvent(e) {
        e.preventDefault();
        e.stopPropagation();
    }

    function loadImageToEditorModal($img, load_and_confirm){
        // Set editing <img> id to 'editingimage' attr
        $canvas.attr('editingimage', $img.attr('id'));
        var ctx = $canvas[0].getContext('2d');
        var image = new Image();
        image.src = $img.attr('src');
        image.onload = function(e){
            var redratio = Math.min(
                1.0, 
                Math.sqrt(MAX_IMAGE_SIZE / (image.width * image.height))
            );
            $canvas.attr({
                width: image.width * redratio,
                height: image.height * redratio
            });
            $canvas_ui.attr({
                width: image.width * redratio,
                height: image.height * redratio
            });
            ctx.drawImage(image, 
                0, 0, 
                image.width * redratio, image.height * redratio
            );
            if(load_and_confirm){
                confirmImageFromEditorModal();
            }
        }
    }

    function confirmImageFromEditorModal(){
        // Confirm edited image
        var dataURI = $canvas[0].toDataURL();
        var $pendingimage = $('#' + $canvas.attr('editingimage'));
        $pendingimage.attr('src', dataURI);
    }

    function loadImages(images){
        $.each(images, function(){
            var reader = new FileReader();
            reader.onload = function(e){
                // Increment ID of images
                imagecount += 1;
                $preview.append($('<img>').attr({
                    src: e.target.result,
                    id: "pending_image_" + imagecount,
                    width: "120px",
                    title: "uploaded_image"
                }));
                var $pendingimage = $("#pending_image_" + imagecount);
                // Make the list of <img> tags
                $pendingimages[imagecount] = $pendingimage;

                // Make the click trigger of <img> tags
                $pendingimage.click(function(e){
                    // Set the image of canvas
                    loadImageToEditorModal($pendingimage);
                    $imageeditmodal.modal('toggle');
                });

                // Once load it on canvas to scale it (for large images)
                loadImageToEditorModal($pendingimage, true);
            }
            reader.readAsDataURL(this);
        })
    }
    
    function pendFile(e){
        e.preventDefault();
        var images = e.originalEvent.dataTransfer.files;

        loadImages(images);
    }

    // Ref: (https://stackoverflow.com/a/15754051)
    function dataURItoBlob(dataURI) {
        var byteString = atob(dataURI.split(',')[1]);
        var ab = new ArrayBuffer(byteString.length);
        var ia = new Uint8Array(ab);
        for (var i = 0; i < byteString.length; i++) {
            ia[i] = byteString.charCodeAt(i);
        }
        return new Blob([ab]);
    }

    // Ref: (https://stackoverflow.com/a/29390393)
    function blobToFile(theBlob, fileName){
        //A Blob() is almost a File() - it's just missing the two properties below which we will add
        theBlob.lastModifiedDate = new Date();
        theBlob.name = fileName;
        return theBlob;
    }

    function dataURItoFile(dataURI, fileName){
        var blob = dataURItoBlob(dataURI);
        var file = blobToFile(blob, fileName);
        file.type = "image/png";
        return file;
    }

    $clickandselect.click(function(){
        $('<input type="file" accept="image/*">').on('change', function(e) {
            var images = e.target.files;
            loadImages(images);
        })[0].click();
    })

    $editconfirm.click(confirmImageFromEditorModal);

    $virtualform.on({
        'dragenter': disableEvent,
        'dragover': disableEvent,
        'dragleave': disableEvent,
        'drop': pendFile
    });

    $postform_submit.click(function(e){
        $('#submit_type').attr('name', $(this).attr('name'))
    })

    $postform.submit(function(e){
        disableEvent(e);

        // Reading all infomations from form
        var fd = new FormData($postform[0]);

        // Appending image files
        var newvalue = [];
        $.each($pendingimages, function(i, $pimage){
            fd.append('post[image][' + i + ']', dataURItoBlob($pimage[0].src));
        });

        $.ajax({
            type: $postform[0].method,
            url: $postform[0].action,
            data: fd,
            processData: false,
            contentType: false,
            dataType: 'json'
        }).done(function(data, status, xhr) {
            // If succeed, reload
            location.reload();
        }).fail(function(xhr, status, error) {
            console.log("Post#Create : " + status + " Error detected.");
        });
    })
})
