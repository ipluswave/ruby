// Requires: fabric.js, config.js, promise.min.js

function Card(template) {
    this._template = "";

    this._customError;
    this._initializationErrors = 0;

    this._options = {
        canvasWidth: 0,
        canvasHeight: 0,
        renderWidth: 0, // if 0 then = canvasWidth value
        renderHeight: 0, // if 0 then = canvasHeight value
        mode: "printing", // "preview" | "previewBarcode" | "printing"
        orientation: "landscape",
        color: "color", // "color" | "black"
        quality: 1, // 0 - 1
        checkRemoveColorFilter: false,
        checkRemoveColorFilterThreshold: 2, // increase this value if the script couldn't detect a faulty card
        fixFontPositionForPrinting: false,
        fixFontPositionForPrintingRatio: 2.3,
        barcodeMode: "fit", // "stretch" | "fit" | "fill" | "natural"
        qrcodeMode: "stretch" // "stretch" | "natural"
    };

    // card.setTemplate(JSON string | parsed JSON object);
    // ***************************************************
    // Use this function to load JSON (string or parsed object)
    // Required if you didn't set it in "new Card()"
    this.setTemplate = function(templateJSON) {
        var shouldParse = false;
        if(typeof templateJSON === "string")
            shouldParse = true;

        if(shouldParse)
            this._template = JSON.parse(templateJSON);
        else
            this._template = templateJSON;

        this._resizeTextObjects();

        if(!this.getOption("canvasWidth") || !this.getOption("canvasHeight"))
            this._setCanvasSizeFromTemplate();
    };

    // var templateJSONstring = card.templateJSON();
    // *********************************************
    // Returns JSON string of the current template
    this.templateJSON = function() {
        return JSON.stringify(this._template);
    };

    // card.setOption(param, value);
    // var value = card.getOption(param);
    // *****************************
    // Some of the params:
    // canvasWidth = int (default: 1012) - use card.setCanvasSize(width, height) instead
    // canvasHeight = int (default: 638) - use card.setCanvasSize(width, height) instead
    // orientation = "landscape"|"portrait" (default: "landscape") - use card.setOrientation(width, height) instead
    // checkRemoveColorFilter = bool (default: false)
    // fixFontPositionForPrinting = bool (default: false) - set to true if position of the text with the font IDAutomationHC39M is too low
    // fixFontPositionForPrintingRatio = float (default: 2.3) - bigger ratio = higher top position of the text with IDAutomationHC39M
    this.setOption = function(param, value) {
        for (var key in this._options) {
            if (!this._options.hasOwnProperty(key)) continue;

            if(key == param) {
                this._options[key] = value;
            }
        }
    };

    this.getOption = function(param) {
        for (var key in this._options) {
            if (!this._options.hasOwnProperty(key)) continue;

            if(key == param)
                return this._options[key];
        }
    };

    // card.setCanvasSize(width, height);
    // **********************************
    // Default: will be set based on the template
    // Not required.
    this.setCanvasSize = function(width, height) {
        this.setOption("canvasWidth", width);
        this.setOption("canvasHeight", height);
    };

    // card.setRenderSize(width, height);
    // card.setRenderSize(biggerSide);
    // **********************************
    // Use this to set the desired size of the rendered image, multiplier will be calculated automatically
    // Default: Equals canvas sizes
    // Not required
    this.setRenderSize = function(width, height) {
        height = height || width;

        this.setOption("renderWidth", width);
        this.setOption("renderHeight", height);
    };

    // card.setOrientation("landscape|portrait");
    // ******************************************
    // Changes canvas side:
    // For example, if current canvas size is 1012x638 and you call this function with parameter "portrait",
    // the canvas size will be set to 638x1012. Nothing else changes.
    // Not required.
    this.setOrientation = function(orient) {
        orient = orient || this.getOption("orientation");
        this.setOption("orientation", orient);

        var biggerSide, smallerSide, biggerSideRender, smallerSideRender;

        if(this.getOption("canvasWidth") > this.getOption("canvasHeight")) {
            biggerSide = this.getOption("canvasWidth");
            smallerSide = this.getOption("canvasHeight");
        }
        else {
            biggerSide = this.getOption("canvasHeight");
            smallerSide = this.getOption("canvasWidth");
        }

        if(this.getOption("renderWidth") > this.getOption("renderHeight")) {
            biggerSideRender = this.getOption("renderWidth");
            smallerSideRender = this.getOption("renderHeight");
        }
        else {
            biggerSideRender = this.getOption("renderHeight");
            smallerSideRender = this.getOption("renderWidth");
        }

        if(orient == "landscape") {
            this.setCanvasSize(biggerSide, smallerSide);
            this.setRenderSize(biggerSideRender, smallerSideRender);
        }
        else {
            this.setCanvasSize(smallerSide, biggerSide);
            this.setRenderSize(smallerSideRender, biggerSideRender);
        }
    };

    // card.setMode("preview|previewBarcode|printing");
    // *********************************
    // Preview mode: magstripe and slot punch images will be added if required
    // Printing mode: renders the template as is
    // Default is "printing"
    // Not required
    this.setMode = function(mode) {
        if(mode == "preview" || mode == "previewBarcode" || mode == "printing")
            this.setOption("mode", mode);
        else
            this.error("error", "incorrect mode, should be 'preview' or 'printing'");
    };

    // card.setColor("color|black");
    // *****************************
    // Color of the rendered image
    // Default is "color"
    this.setColor = function(color) {
        if(color == "color" || color == "black")
            this.setOption("color", color);
        else
            this.error("error", "incorrect color mode, should be 'color' or 'black'");
    };

    // card.setBarcodeMode("stretch|fit|fill|natural");
    // *******************************************
    // Stretch: barcode image will be stretched to the size of the container
    // Fit: barcode image will be resized to fit inside the container while keeping its aspect ratio
    // Fill: barcode image will be resized to fill the container while keeping its aspect ratio
    // Natural: barcode image won't be resized
    // Default is "fit"
    this.setBarcodeMode = function(mode) {
        if(mode == "stretch" || mode == "fit" || mode=="fill" || mode == "natural")
            this.setOption("barcodeMode", mode);
        else
            this.error("error", "incorrect barcode mode, should be 'stretch', 'fit', 'fill' or 'natural'");
    };

    // card.setQRCodeMode("stretch|natural");
    // **************************************
    // Stretch: QR Code will be stretched to the size of the container
    // Natural: QR Code image won't be resized
    // Default is "stretch"
    this.setQRCodeMode = function(mode) {
        if(mode == "stretch" || mode == "fit" || mode=="fill")
            this.setOption("qrcodeMode", "stretch");
        else if(mode == "natural")
            this.setOption("qrcodeMode", mode);
        else
            this.error("error", "incorrect QR code mode, should be 'stretch' or 'natural'");
    };

    // card.setQuality(0-1);
    // *********************
    // Set the quality of the rendered base64 image
    // Default is 1
    this.setQuality = function(quality) {
        if(quality>=0 && quality <= 1)
            this.setOption("quality", quality);
        else
            this.error("error", "incorrect quality setting, should be 0-1");
    };

    // card.json(callback(templateJSON))
    // *********************************
    // Return fixed template json
    this.json = function(callback) {
        var json = JSON.parse(this.templateJSON());

        if(this.getOption("mode") == "preview" || this.getOption("mode") == "previewBarcode")
            json = this._prepareForPreview(json, this);

        if(this.getOption("fixFontPositionForPrinting"))
            json = this._fixFontPositionForPrinting();

        var ref = this;

        ref._resizeBarcodes(json, ref)
            .then(function(result) {
                callback(JSON.stringify(result));
            });
    };

    // card.base64(callback(base64string), format, multiplier)
    // ********************************************************************************
    // Returns base64 string
    // Callback function is required
    // Format is optional, default is 'png'
    // Multiplier is optional, default is 1 if render size isn't set, or automatic if it's set
    // If you set a multiplier, it will override automatic multiplier that is based on the render size
    //
    // Valid examples:
    // card.base64(function(base64) {alert(base64)});
    // card.base64(function(base64) {alert(base64)}, 'jpg');
    // card.base64(function(base64) {alert(base64)}, 2);
    // card.base64(function(base64) {alert(base64)}, 'jpg', 2);
    this.base64 = function(callback, format, multiplier) {
        if(!callback || !isFunction(callback)) {
            this.error("error", "card.base64 requires a callback function!");
            return;
        }

        if(!this._checkTemplate()) return;

        if(!multiplier && typeof format == "number") {
            multiplier = format;
            format = 'png';
        }

        multiplier = multiplier || this._calculateMultiplier();
        format = format || 'png';

        var canvas = new fabric.Canvas();

        canvas.setWidth(this.getOption("canvasWidth"));
        canvas.setHeight(this.getOption("canvasHeight"));

        var json = JSON.parse(this.templateJSON());

        if(this.getOption("mode") == "preview" || this.getOption("mode") == "previewBarcode")
            json = this._prepareForPreview(json, this);

        if(this.getOption("fixFontPositionForPrinting"))
            json = this._fixFontPositionForPrinting();

        var checkRemoveColorFilter = this.getOption("checkRemoveColorFilter"),
            grayscale = false,
            ref;

        if(this.getOption("color") == "black")
            grayscale = true;

        if(grayscale)
            json = this._removeGrayscaleFilters(json); // remove grayscale filters from objects because they are not needed - the filter will be applied to the entire image instead

        ref = this;

        // Using JS Promises to chain async functions: http://exploringjs.com/es6/ch_promises.html
        ref._resizeBarcodes(json, ref)
            .then(function(result) {
                return ref._getBase64FromJSON(result, ref, format, multiplier);
            })
            .then(function(result) {
                if(checkRemoveColorFilter)
                    return ref._checkImageForColors(ref, result);
                else
                    return result;
            })
            .then(function(result) {
                if(grayscale)
                    return ref._base64toGrayscale(result);
                else
                    return result;
            })
            .then(function(result) {
                callback(result);
            });
    };



    /**********/
    /*  UTIL  */
    /**********/
    // card.errorHandler(function(type, msg));
    // ***************************************************
    // You can set up your own function to deal with errors
    // Default error handler is console.log(type + ": " + msg);
    // Types: "error", "warning"
    // Not required
    this.errorHandler = function(func) {
        if(func.length == 2)
            this._customError = func;
        else
            this.error("error", "incorrect number of arguments in the errorHandler function! It should look like this: card.errorHandler(function(type, msg){...");

        if(this._initializationErrors > 0) {
            this.error("error", "there's an initialization error!");
            this._initializationErrors = 0;
        }
    };

    function isFunction(functionToCheck) {
        var getType = {};
        return functionToCheck && getType.toString.call(functionToCheck) === '[object Function]';
    }

    this.error = function(type, msg) {
        if(!this._customError || !isFunction(this._customError)) {
            console.log(type + ": " + msg);
        }
        else {
            this._customError(type, msg);
        }
    };

    // Function that checks if template is loaded and correct. Returns true|false. Shows an error message if the template is missing or broken.
    this._checkTemplate = function() {
        if(!this._template) {
            this.error("error", "the template is empty");
            return false;
        }

        return true;
    };

    // Function that resizes text objects to fit into their rect boxes
    this._resizeTextObjects = function() {
        if(!this._checkTemplate()) return;

        for(var i=0; i<this._template.objects.length; i++) {
            this._resizeObject(this._template.objects[i]);

            if(this._template.objects[i].type == "rect" && this._template.objects[i].name == "textRect") {
                var text = false,
                    rect = this._template.objects[i];

                for(var z=0; z<this._template.objects.length; z++) {
                    if(this._template.objects[z].type == "static-text" && this._template.objects[z].textID == rect.textID)
                        text = this._template.objects[z];
                }

                if(text)
                    this._recalcPositionOfResizedText(text, rect);
            }
        }
    };

    // Function that resizes a text object to fit into its rect box
    this._resizeObject = function(object) {
        if(object.type=="static-text") // temporary fix for the issue with text that has: Auto-resize = Off and No clipping = Off
            object.noClip = true;

        if(object.type=="static-text" && object.autoResize == true) {
            if(object.clipWidth <= 0 || object.clipHeight <= 0)
                return;

            var boxWidth = object.clipWidth,
                boxHeight = object.clipHeight;

            var fontSize = object.fontSize;
            if(object.fontSizeOriginal) fontSize = object.fontSizeOriginal;

            var text = new fabric.StaticText(object.text, {
                fontFamily: object.fontFamily,
                fontWeight: object.fontWeight,
                fontStyle: object.fontStyle,
                fontSize: fontSize
            });

            while(text.getWidth() > boxWidth || text.getHeight() > boxHeight) {
                text = new fabric.StaticText(text.text, {
                    fontFamily: text.fontFamily,
                    fontWeight: text.fontWeight,
                    fontStyle: text.fontStyle,
                    fontSize: text.fontSize - 0.5
                });
            }

            object.width = text.getWidth();
            object.height = text.getHeight();
            object.fontSize = text.fontSize;
            object.clipTo = false;
        }
    };

    // Set the canvas size based on the background image of the template
    this._setCanvasSizeFromTemplate = function() {
        if(!this._checkTemplate()) return;

        if(!this._template.backgroundImage || !this._template.backgroundImage.width || !this._template.backgroundImage.height) {
            this.error("error", "can't set canvas size");
            return;
        }

        this.setCanvasSize(this._template.backgroundImage.width, this._template.backgroundImage.height);
        this._setOrientationFromCanvasSize();

        if(!this.getOption("renderWidth") || !this.getOption("renderHeight")) {
            this.setRenderSize(this.getOption("canvasWidth"), this.getOption("canvasHeight"));
        }
    };

    this._setOrientationFromCanvasSize = function() {
        if(this.getOption("canvasWidth") > this.getOption("canvasHeight"))
            this.setOption("orientation", "landscape");
        else
            this.setOption("orientation", "portrait");
    };

    // Function that repositions resized text object according to their rect boxes,
    // it also takes into account left/center/right text alignment
    this._recalcPositionOfResizedText = function(text, rect) {
        var left = rect.left,
            top = rect.top,
            angle = rect.angle,
            rectLeft = left,
            rectTop = top;

        if(rect.originX == "center") {
            var point = rect.translateToOriginPoint(new fabric.Point(left, top), "left", "top");
            rectLeft = point.x;
            rectTop = point.y;
        }

        if(text.textAlign == "center") {
            if(angle==270) {
                top = rectTop - (rect.width - text.width)/2;
                left = rectLeft;
            }
            else if(angle==90) {
                top = rectTop + (rect.width - text.width)/2;
                left = rectLeft;
            }
            else if(angle==180) {
                top = rectTop;
                left = rectLeft - (rect.width - text.width)/2;
            }
            else {
                left = rectLeft + (rect.width - text.width)/2;
                top = rectTop;
            }
        }
        else if(text.textAlign == "right") {
            if(angle==270) {
                top = rectTop - (rect.width - text.width);
                left = rectLeft;
            }
            else if(angle==90) {
                top = rectTop + (rect.width - text.width);
                left = rectLeft;
            }
            else if(angle==180) {
                top = rectTop;
                left = rectLeft - (rect.width - text.width);
            }
            else {
                left = rectLeft + (rect.width - text.width);
                top = rectTop;
            }
        }
        else {
            left = rectLeft;
            top = rectTop;
        }

        text.left = left;
        text.top = top;
        text.angle = rect.angle;
    };

    this._fixFontPositionForPrinting = function() {
        var listOfFonts = [{name: "IDAutomationHC39M", ratio: this.getOption("fixFontPositionForPrintingRatio")}]; // bigger ratio = higher top position of the text
        var json = JSON.parse(this.templateJSON());

        for(var i=0; i<json.objects.length; i++) {

            if(json.objects[i].type == "static-text") {

                for(var z=0; z<listOfFonts.length; z++) {

                    if(json.objects[i].fontFamily == listOfFonts[z].name) {
                        // find the text rect of this object and change its position
                        var paddingTop = json.objects[i].fontSize * listOfFonts[z].ratio,
                            rectID = json.objects[i].textID;

                        json.objects[i].top -= paddingTop;

                        for(var y=0; y<json.objects.length; y++) {
                            if(json.objects[y].type == "rect" && json.objects[y].textID == rectID)
                                json.objects[y].top -= paddingTop;
                        }

                    }

                }

            }

        }

        return json;
    };

    // Calculates multipliers needed to resize the card from canvas size to render size
    this._calculateMultiplier = function() {
        var canvasWidth = this.getOption("canvasWidth"),
            canvasHeight = this.getOption("canvasHeight"),
            renderWidth = this.getOption("renderWidth"),
            renderHeight = this.getOption("renderHeight");

        if(!canvasWidth || !canvasHeight) {
            this.error("error", "can't calculate the size of the image");
            return 1;
        }

        if(!renderWidth || !renderHeight) {
            return 1;
        }

        var multiWidth = renderWidth / canvasWidth;
        var multiHeight = renderHeight / canvasHeight;

        if(multiHeight > multiWidth)
            return multiWidth;
        else
            return multiHeight;
    };

    // Checks if the image has colors that should be transparent
    // Async
    this._checkImageForColors = function(ref, base64) {
        return new Promise(function(resolve, reject){
            var threshold = ref.getOption("checkRemoveColorFilterThreshold");
            function success() {
                return resolve(base64);
            }
            function error() {
                ref.error("warning", "the remove color filter might have failed");
                success();
            }
            function opacityWarning() {
                // _checkImageForColors function can't detect errors if the image with RemoveWhite filter is also transparent, so it should show a warning
                ref.error("warning", "there's a transparent image with a RemoveWhite filter, you might need to check if it was drawn correctly");
            }

            if(!ref._checkTemplate()) reject(base64);

            // get colors that should be transparent
            var colorsToCheck = [];
            for(var i=0; i<ref._template.objects.length; i++) {
                if(ref._template.objects[i].type == "image" || ref._template.objects[i].type == "variable-image") {
                    for(var z=0; z<ref._template.objects[i].filters.length; z++) {
                        if(ref._template.objects[i].filters[z] && ref._template.objects[i].filters[z].type == "RemoveWhite") {
                            colorsToCheck.push(ref._template.objects[i].filters[z].color);

                            if(ref._template.objects[i].opacity != 1)
                                opacityWarning();

                        }
                    }
                }
            }

            if(colorsToCheck.length == 0) {
                success();
            }

            var image = new Image();
            image.onload = function() {
                var canvasTmp = document.createElement('canvas');
                canvasTmp.width = image.width;
                canvasTmp.height = image.height;

                var context = canvasTmp.getContext('2d');
                context.drawImage(image, 0, 0);

                var imageData = context.getImageData(0, 0, canvasTmp.width, canvasTmp.height);

                for(i=0; i<imageData.data.length; i+=4) {
                    var red = imageData.data[i];
                    var green = imageData.data[i+1];
                    var blue = imageData.data[i+2];

                    for(var z=0; z<colorsToCheck.length; z++) {
                        if( (red > colorsToCheck[z][0]-threshold && red < colorsToCheck[z][0]+threshold) &&
                            (green > colorsToCheck[z][1]-threshold && green < colorsToCheck[z][1]+threshold) &&
                            (blue > colorsToCheck[z][2]-threshold && blue < colorsToCheck[z][2]+threshold)) {
                            error();
                            return;
                        }
                    }
                }

                success();
            };

            image.onerror = function(){
                reject(base64)
            };

            image.src = base64;
        });
    };

    // Async
    this._getBase64FromJSON = function(json, ref, format, multiplier) {
        return new Promise(function(resolve){
            var canvas = new fabric.Canvas();

            canvas.setWidth(ref.getOption("canvasWidth"));
            canvas.setHeight(ref.getOption("canvasHeight"));

            canvas.loadFromJSON(json, function() {
                return resolve(canvas.toDataURLWithMultiplier(format, multiplier, ref.getOption("quality")));
            });
        });
    };

    // Adds slot punch and magstripe images
    this._prepareForPreview = function(data, ref) {
        function setPreviewBarcodeImage(oldVal, newVal) {
            if(ref.getOption("mode") == "preview" || oldVal[0] == "{")
                return newVal;
            else
                return oldVal;
        }

        for(var i=0; i<data.objects.length; i++) {
            var isSlotPunch = false;
            if(data.objects[i].type == "rect" && data.objects[i].rx == 10 && data.objects[i].ry == 10 && data.objects[i].fill == 'rgba(0,0,0,0)' && data.objects[i].stroke == 'rgba(0,0,0,0)') {
                isSlotPunch = true;
            }

            if(data.objects[i].type == "static-text" || data.objects[i].type == "variable-text") {
                data.objects[i].fontSizeOriginal = data.objects[i].fontSize;
            }

            if((data.objects[i].type == "static-text" || data.objects[i].type == "variable-text") && data.objects[i].text.substring(0,3)=="{{{") {
                if(data.objects[i].fieldName && data.objects[i].fieldName != "")
                    data.objects[i].text = data.objects[i].fieldName;
                else
                    data.objects[i].text = this._stripBrackets(data.objects[i].text);
            }
            else if(data.objects[i].type == "image") {
                if(data.objects[i].name && data.objects[i].name.slice(0,8) == "embedded")
                {
                    data.objects[i].opacity = data.objects[i].actualOpacity;
                }
            }
            else if(data.objects[i].type == "variable-image" && data.objects[i].src.substring(0,3)=="{{{") {
                if(data.objects[i].fieldName && data.objects[i].fieldName != "")
                    data.objects[i].name = data.objects[i].fieldName;
                else
                    data.objects[i].name = this._stripBrackets(data.objects[i].src);

                data.objects[i].src = config.varIMG;
            }
            else if((data.objects[i].type == "rect" && data.objects[i].name == "slotPunch") || isSlotPunch) {
                data.objects[i].name = "slotPunch";
                data.objects[i].fill = '#2a3035';
                data.objects[i].stroke = '#697884';
            }
            else if(data.objects[i].type == "rect" && data.objects[i].name == "magStripe") {
                data.objects[i].fill = '#000';
            }
            else if(data.objects[i].type == "barcode" && data.objects[i].barcodeType == "qrcode") {
                data.objects[i].src = config.barcodeIMG.qrcode;
            }
            else if(data.objects[i].type == "barcode" && (data.objects[i].barcodeType == "code39" || data.objects[i].barcodeType == "code39extended")) {
                data.objects[i].src = setPreviewBarcodeImage(data.objects[i].src, config.barcodeIMG.code39);
            }
            else if(data.objects[i].type == "barcode" && (data.objects[i].barcodeType == "Code25" || data.objects[i].barcodeType == "Code25Interleaved" || data.objects[i].barcodeType == "Code25IATA")) {
                data.objects[i].src = setPreviewBarcodeImage(data.objects[i].src, config.barcodeIMG.code25);
            }
            else if(data.objects[i].type == "barcode" && data.objects[i].barcodeType.slice(0, -1) == "code128") {
                data.objects[i].src = setPreviewBarcodeImage(data.objects[i].src, config.barcodeIMG.code128);
            }
        }

        return data;
    };

    // Removes grayscale filters from objects
    this._removeGrayscaleFilters = function(data) {
        for(var i=0; i<data.objects.length; i++) {
            if(data.objects[i].filters)
                data.objects[i].filters[0] = false;
        }

        return data;
    };

    this._stripBrackets = function(str) {
        if(str.substring(0, 3)=="{{{")
            return str.substring(3, str.length-3);
        else
            return str;
    };

    // Make base64 image grayscale
    // Async
    this._base64toGrayscale = function(base64) {
        return new Promise(function(resolve, reject){
            var canvas = document.createElement("canvas");
            var ctx = canvas.getContext("2d");

            var image = new Image();

            image.onload = function(){
                canvas.width=image.width;
                canvas.height=image.height;
                ctx.drawImage(image, 0, 0);

                var imageData=ctx.getImageData(0,0,canvas.width,canvas.height);
                var data=imageData.data;

                for(var i=0;i<data.length;i+=4){
                    data[i+0]=data[i+1]=data[i+2]=(data[i]+data[i+1]+data[i+2])/3;
                }
                ctx.putImageData(imageData,0,0);

                base64 = canvas.toDataURL();

                return resolve(base64)
            };

            image.onerror = function(){
                return reject(base64)
            };

            image.src = base64
        });
    };

    // Resize barcode objects to get rid of stretching
    // Async
    this._resizeBarcodes = function(json, ref) {
        return new Promise(function(resolve, reject){
            if(ref.getOption("barcodeMode") == "stretch" && ref.getOption("qrcodeMode") == "stretch")
                return resolve(json);

            var barcodes = [];

            for(var i=0; i<json.objects.length; i++) {
                if(json.objects[i].type == "barcode") {
                    var barcodeType = "barcode";

                    if(json.objects[i].barcodeType == "qrcode")
                        barcodeType = "qrcode";

                    if(barcodeType == "barcode" && ref.getOption("barcodeMode") == "stretch")
                        continue;
                    else if(barcodeType == "qrcode" && ref.getOption("qrcodeMode") == "stretch")
                        continue;

                    barcodes.push({
                        type: barcodeType,
                        name: json.objects[i].name,
                        base64: json.objects[i].src,
                        oldWidth: json.objects[i].width,
                        oldHeight: json.objects[i].height,
                        oldTop: json.objects[i].top,
                        oldLeft: json.objects[i].left,
                        naturalWidth: 0,
                        naturalHeight: 0,
                        width: 0,
                        height: 0,
                        top: 0,
                        left: 0
                    });
                }
            }

            function getRealSizes(id) {
                // do async resizing stuff here
                var img = new Image();

                img.onload = function(){
                    barcodes[id].naturalWidth = img.naturalWidth;
                    barcodes[id].naturalHeight = img.naturalHeight;

                    if(id+1 < barcodes.length)
                        getRealSizes(id+1);
                    else {

                        for(var barcode of barcodes) {

                            for(var obj of json.objects) {
                                if(obj.name && obj.name == barcode.name) {
                                    var ratioW = barcode.oldWidth / barcode.naturalWidth;
                                    var ratioH = barcode.oldHeight / barcode.naturalHeight;
                                    var ratio = 1;

                                    if(barcode.type == "barcode" && ref.getOption("barcodeMode") == "fit")
                                        ratio = Math.min(ratioH, ratioW);
                                    else if(barcode.type == "barcode" && ref.getOption("barcodeMode") == "fill")
                                        ratio = Math.max(ratioH, ratioW);
                                    // natural: ratio = 1

                                    barcode.width = barcode.naturalWidth * ratio;
                                    barcode.height = barcode.naturalHeight * ratio;

                                    if(obj.angle == 270) {
                                        barcode.left = barcode.oldLeft + (barcode.oldHeight - barcode.height) / 2;
                                        barcode.top = barcode.oldTop - (barcode.oldWidth - barcode.width) / 2;
                                    }
                                    else if(obj.angle == 90) {
                                        barcode.left = barcode.oldLeft + (barcode.oldHeight - barcode.height) / 2;
                                        barcode.top = barcode.oldTop + (barcode.oldWidth - barcode.width) / 2;
                                    }
                                    else {
                                        barcode.left = barcode.oldLeft + (barcode.oldWidth - barcode.width) / 2;
                                        barcode.top = barcode.oldTop + (barcode.oldHeight - barcode.height) / 2;
                                    }

                                    obj.width = barcode.width;
                                    obj.height = barcode.height;
                                    obj.top = barcode.top;
                                    obj.left = barcode.left;
                                }
                            }

                        }

                        //////////////

                        return resolve(json);
                    }
                };

                img.src = barcodes[id].base64;
            }

            if(barcodes.length > 0)
                getRealSizes(0);
            else
                return resolve(json);
        });
    };

    /********************/
    /*  Initialization  */
    /********************/
    if(typeof fabric == "undefined") {
        this.error("error", "couldn't load fabric.js!");
        this._initializationErrors++;
    }

    if(template != false) {
        this.setTemplate(template);
    }
}