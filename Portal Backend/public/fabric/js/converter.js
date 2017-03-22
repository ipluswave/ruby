var cleanTemplate = '{"objects":[],"background":"","backgroundImage":{"type":"image","originX":"left","originY":"top","left":0,"top":0,"width":457,"height":288,"fill":"rgb(0,0,0)","stroke":null,"strokeWidth":1,"strokeDashArray":null,"strokeLineCap":"butt","strokeLineJoin":"miter","strokeMiterLimit":10,"scaleX":1,"scaleY":1,"angle":0,"flipX":false,"flipY":false,"opacity":1,"shadow":null,"visible":true,"clipTo":null,"backgroundColor":"","fillRule":"nonzero","globalCompositeOperation":"source-over","src":"data:image/gif;base64,R0lGODlhAQABAPAAAP///////yH5BAAAAAAALAAAAAABAAEAAAICRAEAOw==","filters":[],"crossOrigin":"","alignX":"none","alignY":"none","meetOrSlice":"meet"}}';

var templateData;
// 1020:640 = 457:288
// 1013:638? 638 x 1012

var cardWidth = 1012,
    cardHeight = 638,
    coeff = 1;
/*
var fontInfo = [{
    name: "Calibri",
    lineHeight: 1.108
}];*/

// MAX(usWinAscent + usWinDescent, Ascender - Descender + LineGap)
// Calibri: 2500 = 1.216
// unitsPerEm = 2048   2500/2048 = 1.22 <- best one
// 2500 / usWinAscent (1950) = 1.28
// find ~2055
// 1.1 - real lineHeight

// (lineHeight - fontSize)/2
// 0.108

// Arial:
// MAX(usWinAscent + usWinDescent, Ascender - Descender + LineGap)
// MAX(1854 + 434, 1854 + 434 + 67) = 2355
// Arial: 2355 = ?
// 2355 / unitsPerEm (2048) = 1.15 - line gap

//////////////////////////////////////////////////////////////
// !!!!!! HOW TO CALCULATE CORRECT RELATIVE LINE HEIGHT !!!!!!
//
// windows_line_height = ascender - descender + lineGap;
// or
// windows_line_height = usWinAscent + usWinDescent;
//
// relative_windows_line_height = windows_line_height / unitsPerEm;
//
// line_height = relative_windows_line_height - (relative_windows_line_height - 1)/2;
//
//////////////////////////////////////////////////////////////

/*
var cardWidth = 457,
    cardHeight = 288,
    coeff = 1013/cardWidth;*/

    var files = [],
        fileList = [{}],
        fieldData = [],
        template,
        mag_stripe = false,
        basicTemplate = {
            id: 0,
            name: "test template name",
            organization_id: 4,
            card_type_id: 1,
            front_data: null,
            back_data: null,
            options: [
                {
                    "key": "sides",
                    "value": "double"
                },
                {
                    "key": "orientation",
                    "value": "landscape"
                },
                {
                    "key": "color",
                    "value": "colorcolor"
                },
                {
                    "key": "slot_punch",
                    "value": "none"
                },
                {
                    "key": "overlay",
                    "value": false
                }
            ],
            "images": [],
            "template_fields": [],
            "card_data": [],
            "special_handlings": []
        };

    function stripBrackets(string) {
        if(string.substring(0, 3)=="{{{")
            return string.substring(3, string.length-3);
        else
            return string;
    }

    function unsupportedCharactersToUnderscore(string) {
        return string.replace(/[^\w.-]/gi, '_');;
    }

    function removeUnsupportedCharacters(string) {
        return string.replace(/[^\w]/gi, '');
    }

    function setOptionValueByKey(key, value) {
        for(i=0; i<template.options.length; i++) {
            if(template.options[i].key == key)
                template.options[i].value = value;
        }
    }

    function getOptionValueByKey(key) {
        for(i=0; i<template.options.length; i++) {
            if(template.options[i].key == key)
                return template.options[i].value;
        }
    }

    function prepareTemplateForPreview(data) {
        for(i=0; i<data.objects.length; i++) {
            if(data.objects[i].type=="static-text") {
                data.objects[i].text = stripBrackets(data.objects[i].text);
            }
            else if(data.objects[i].type == "variable-image") {
                data.objects[i].name = stripBrackets(data.objects[i].src);
                data.objects[i].src = config.varIMG;
            }
            else if(data.objects[i].type == "barcode" && data.objects[i].barcodeType == "qrcode") {
                data.objects[i].src = config.barcodeIMG.qrcode;
            }
            else if(data.objects[i].type == "barcode") {
                data.objects[i].src = config.barcodeIMG.code39;
            }
            else if(data.objects[i].name == "slotPunch") {
                data.objects[i].fill = '#2a3035';
                data.objects[i].stroke = '#697884';
            }
            else if(data.objects[i].type == "rect" && data.objects[i].name == "magStripe") {
                data.objects[i].fill = '#000';
            }
        }

        return data;
    }

    function generateTemplatePreviewBase64(frontJSON, backJSON) {
        if(frontJSON) {
            $('.previewFront').attr("src", "");

            var data = JSON.parse(frontJSON);
            var previewCanvas = new fabric.Canvas(document.createElement('canvas'));

            if(data.backgroundImage) {
                previewCanvas.setHeight(data.backgroundImage.height);
                previewCanvas.setWidth(data.backgroundImage.width);
            }

            previewCanvas.loadFromJSON(frontJSON, function () {
                var img = previewCanvas.toDataURL("image/png");
                $('.previewFront').attr("src", img);
            });
        }

        if(backJSON) {
            $('.previewBack').attr("src", "");

            var data = JSON.parse(backJSON);
            var previewCanvas2 = new fabric.Canvas(document.createElement('canvas'));

            if(data.backgroundImage) {
                previewCanvas2.setHeight(data.backgroundImage.height);
                previewCanvas2.setWidth(data.backgroundImage.width);
            }

            previewCanvas2.loadFromJSON(backJSON, function() {
                var img = previewCanvas2.toDataURL("image/png");
                $('.previewBack').attr("src", img);

                /*
                var orient = getOptionValueByKey("orientation");
                $('#loading').addClass('hidden');
                if(orient=="portrait") {
                    $('#portrait').removeClass('hidden');
                    $('#landscape').addClass('hidden');
                }
                else {
                    $('#portrait').addClass('hidden');
                    $('#landscape').removeClass('hidden');
                }*/
            });
        }
    }

    function addGenericObject() {
        templateData.objects.push({
            originX:    "left",
            originY:    "top",
            "strokeDashArray":null,
            "strokeLineCap":"butt",
            "strokeLineJoin":"miter",
            "strokeMiterLimit":10,
            "scaleX":1,
            "scaleY":1,
            "angle":0,
            "flipX":false,
            "flipY":false,
            "shadow":null,
            "visible":true,
            "clipTo":null,      // ????
            "backgroundColor":"",
            "fillRule":"nonzero",
            "globalCompositeOperation":"source-over",
            "crossOrigin":"*",  // ????
            "alignX":"none",
            "alignY":"none",
            "meetOrSlice":"meet",
            "selectable":true,  // ????
            "evented":true      // ????
        });

        return templateData.objects[templateData.objects.length-1];
    }

    function intToRGB(number, opacity) {
        // the color is in BGR format, so you can't just hex it

        var R = Math.floor(number % 256);
        var G = Math.floor((number / 256) % 256);
        var B = Math.floor((number / 256 / 256) % 256);

        if(typeof(opacity) == 'undefined')
            return "rgb("+R+","+G+","+B+")";
        else
            return "rgba("+R+","+G+","+B+","+opacity+")";
    }

    function scale(int) {
        var newFloat = int/coeff,
            newInt = Math.ceil(newFloat);

        /*
        if(Math.abs(newInt - cardWidth)<2)
            newInt = cardWidth;
        else if(Math.abs(newInt - cardHeight)<2)
            newInt = cardHeight;*/

        return newFloat;
    }

    function scaleDown(int) {
        var coeff = 457 / 1012,
            newFloat = int*coeff;

        return newFloat;
    }

    function swapImagesToBase64(data, images, isFront) {
        for (i=0; i<data.objects.length; i++) {
            if (data.objects[i].type == "image") {
                for(z=0; z<images.length; z++) {
                    if(images[z].src == data.objects[i].src) {
                        data.objects[i].src = 'data:image/jpeg;base64,'+images[z].base64;
                        break;
                    }
                }
            }
        }

        if(isFront)
            generateTemplatePreviewBase64(JSON.stringify(data), false);
        else
            generateTemplatePreviewBase64(false, JSON.stringify(data));
    }

    var base64Images = [];
    function addImage(object) {
        var imgUrl = object.ITEMTEXT,
            substr = "\\",
            path = imgUrl.split(substr),
            filters = [{},{}];

        var stroke = null,
            strokeWidthNew = 0,
            strokeShow = false;

        if(parseInt(object.PLWIDTH) != 0) {
            stroke = intToRGB(object.PLCOLOR);

            strokeWidthNew = scale(object.PLWIDTH);
            if(strokeWidthNew<1) strokeWidthNew = 1;

            strokeShow = true;
        }

        var imgUrl = path[path.length-1];

        // actual width & height of the image file
        var imgWidth = object.GRAPHICWIDTH,
            imgHeight = object.GRAPHICHEIGHT,
            left, top, width, height;

        if(object.PICPOS == 0) { // center (no resizing)
            left = -(scale(imgWidth) - cardWidth)/2;
            top = -(scale(imgHeight) - cardHeight)/2;
            width = scale(imgWidth);
            height = scale(imgHeight);
        }
        else if(object.PICPOS == 2) { // fit to left
            left = scale(object.TOPLEFTX);
            top = scale(object.TOPLEFTY);
            width = scale(object.BOTTOMRIGHTX - object.TOPLEFTX);
            height = scale(object.BOTTOMRIGHTY - object.TOPLEFTY);

            var ratioTo = width / height,
                ratioFrom = imgWidth / imgHeight,
                scaleRatio = 1;

            if(ratioFrom >= ratioTo) {
                scaleRatio = width / imgWidth;
            }
            else {
                scaleRatio = height / imgHeight;
            }

            width = imgWidth * scaleRatio;
            height = imgHeight * scaleRatio;
        }
        else { // stretch (1)
            left = scale(object.TOPLEFTX);
            top = scale(object.TOPLEFTY);
            width = scale(object.BOTTOMRIGHTX - object.TOPLEFTX);
            height = scale(object.BOTTOMRIGHTY - object.TOPLEFTY);
        }

        var shouldAddImage = true;

        for(var z=0; z<base64Images.length; z++) {
            if(base64Images[z].src == imgUrl) {
                shouldAddImage = false;
                break;
            }
        }

        if(shouldAddImage) {
            base64Images.push({
                src: imgUrl,
                base64: object.GRAPHIC
            });
        }

        // ItemFontHAlign = B&W
        // ItemFontVAlign = opacity intencity; 0 to -255
        // ItemFontColor = crop color
        if(object.ITEMFONTHALIGN<1) {
            filters[0].type = "Grayscale";
        }

        if(object.ITEMFONTVALIGN<1) {
            filters[1].type = "RemoveWhite";
            filters[1].threshold = object.ITEMFONTVALIGN*-1;

            var color = intToRGB(object.ITEMFONTCOLOR);
            color = color.substring(4, color.length-1).replace(/ /g, '').split(',');

            for(i=0; i<color.length; i++)
                color[i] = parseInt(color[i]);

            filters[1].color = color;
        }

        $.extend(addGenericObject(), {
            type:           "image",
            left:           left,
            top:            top,
            width:          width,
            height:         height,
            fill:           "rgb(0,0,0)",
            stroke:         stroke,
            strokeWidth:    0,
            opacity:        1,
            src:            imgUrl,
            filters:        filters,
            strokeWidthNew: strokeWidthNew,
            cornerRadius:   0,
            strokeShow:     strokeShow
        });
    }

    function addVarImage(object) {
        var token = "Logo";
        if(object.ITEMTYPE == "10") token = "Portrait";
        else if(object.ITEMTYPE == "11") token = "Signature";
        var label = token;

        var stroke = null,
            strokeWidthNew = 0,
            strokeShow = false,
            top = scale(object.TOPLEFTY),
            left = scale(object.TOPLEFTX),
            width = scale(object.BOTTOMRIGHTX - object.TOPLEFTX),
            height = scale(object.BOTTOMRIGHTY - object.TOPLEFTY);

        if(parseInt(object.PLWIDTH) != 0) {
            stroke = intToRGB(object.PLCOLOR);

            strokeWidthNew = scale(object.PLWIDTH)*2;
            if(strokeWidthNew<1) strokeWidthNew = 2;

            left += strokeWidthNew/2;
            top += strokeWidthNew/2;
            width -= strokeWidthNew;
            height -= strokeWidthNew;
            strokeWidthNew = strokeWidthNew*2;

            strokeShow = true;
        }

        if(object.ITEMTYPE=="12") {
            var data_num = parseInt(object.PICPOS) * -1 - 200;

            for (i = 0; i < fieldData.length; i++) {
                if (fieldData[i].data_num == data_num) {
                    label = fieldData[i].data_name;
                    token = removeUnsupportedCharacters(spaceToUnderscore(label));
                }
            }
        }

        template.template_fields.push({
            "type":         "image",
            "dimensions":   {
                "width":    scaleDown(width),
                "height":   scaleDown(height)
            },
            "token":        token,
            "label":        label
        });

        var scaleType = "fit";
        if(object.PICPOS=="1") scaleType = "stretch";
        else if(object.PICPOS=="2") scaleType = "crop";

        // GET SRC FROM FIELDS
        $.extend(addGenericObject(), {
            type:           "variable-image",
            left:           left,
            top:            top,
            width:          width,
            height:         height,
            fill:           "rgb(0,0,0)",
            stroke:         stroke,
            strokeWidth:    0,
            strokeWidthNew: strokeWidthNew,
            cornerRadius:   0,
            src:            "{{{"+token+"}}}",
            fieldName:      label,
            opacity:        1,
            filters:        [],
            cornerRadius:   0,
            strokeShow:     strokeShow,
            scaleType:      scaleType
        });
    }

    function generateBarcodeToken() {
        var id = 0;

        for(var i=0; i<templateData.objects.length; i++) {
            if(templateData.objects[i].type=="barcode" && templateData.objects[i].barcodeType != "qrcode")
                id++;
        }

        if(template.front_data && template.front_data.objects && template.front_data.objects.length > 0) {
            for(var i=0; i<template.front_data.objects.length; i++) {
                if(template.front_data.objects[i].type=="barcode" && template.front_data.objects[i].barcodeType != "qrcode")
                    id++;
            }
        }

        return "barcode_"+id.toString();
    }

    function generateQrcodeToken() {
        var id = 0;

        for(var i=0; i<templateData.objects.length; i++) {
            if(templateData.objects[i].type=="barcode" && templateData.objects[i].barcodeType == "qrcode")
                id++;
        }

        if(template.front_data && template.front_data.objects && template.front_data.objects.length > 0) {
            for(var i=0; i<template.front_data.objects.length; i++) {
                if(template.front_data.objects[i].type=="barcode" && template.front_data.objects[i].barcodeType == "qrcode")
                    id++;
            }
        }

        return "qrcode_"+id.toString();
    }

    function addBarcode(object) {
        var data_num = parseInt(object.PICPOS)*-1-200,
            token = generateBarcodeToken();

        var symbology = "", errorSymbology = "";
        switch(object.ITEMFONTSTYLE) {
            case "3":
                symbology = "code39";
                break;
            case "4":
                symbology = "code39extended";
                break;
            case "5":
                symbology = "code128A";
                break;
            case "6":
                symbology = "code128B";
                break;
            case "7":
                symbology = "code128C";
                break;
            case "0":
                errorSymbology = "Code_2_5_interleaved";
                break;
            case "1":
                errorSymbology = "Code_2_5_industrial";
                break;
            case "2":
                errorSymbology = "Code_2_5_matrix";
                break;
            case "8":
                errorSymbology = "Code93";
                break;
            case "9":
                errorSymbology = "Code93Extended";
                break;
            case "10":
                errorSymbology = "CodeMSI";
                break;
            case "11":
                errorSymbology = "CodePostNet";
                break;
            case "12":
                errorSymbology = "CodeCodabar";
                break;
            case "13":
                errorSymbology = "CodeEAN8";
                break;
            case "14":
                errorSymbology = "CodeEAN13";
                break;
            case "15":
                errorSymbology = "CodeUPC_A";
                break;
            case "16":
                errorSymbology = "CodeUPC_E0";
                break;
            case "17":
                errorSymbology = "CodeUPC_E1";
                break;
            case "18":
                errorSymbology = "CodeUPC_Supp2";
                break;
            case "19":
                errorSymbology = "CodeUPC_Supp5";
                break;
            case "20":
                errorSymbology = "CodeEAN128A";
                break;
            case "21":
                errorSymbology = "CodeEAN128B";
                break;
            case "22":
                errorSymbology = "CodeEAN128C";
                break;
            case "23":
                errorSymbology = "QRCode";
                break;
            default:
                symbology = "code39";
                addMessage("The barcode's symbology (Unknown) is not supported, it was changed to code39", "warning");
                break;
        }

        if(errorSymbology && !symbology) {
            symbology = "code39";
            addMessage("The barcode's symbology ("+errorSymbology+") is not supported, it was changed to code39", "warning");
        }

        for(i=0; i<fieldData.length; i++) {
            if(fieldData[i].data_num == data_num) {
                var label = removeFieldType(fieldData[i].data_name);

                template.template_fields.push({
                    type:   "barcode",
                    token:  removeUnsupportedCharacters(spaceToUnderscore(label)),
                    label:  label
                });

                template.card_data.push({
                    type: "barcode",
                    token: token,
                    data: [
                        {
                            "symbology": symbology
                        },
                        {
                            "barcode": "{{{"+removeUnsupportedCharacters(spaceToUnderscore(label))+"}}}"
                        }
                    ]
                });

            }
        }

        //TODO: background color
        var left, top, width, height,
            angle = parseInt(object.ITEMFONTORIENT);

        if(angle == 180) {
            angle = 0;
            addMessage("Please check the position of the barcode", "warning");
        }

        if(angle == 0) {
            width = parseInt(object.BOTTOMRIGHTX) - parseInt(object.TOPLEFTX);
            height = parseInt(object.BOTTOMRIGHTY) - parseInt(object.TOPLEFTY);
            left = parseInt(object.TOPLEFTX) + width/2;
            top = parseInt(object.TOPLEFTY) + height/2;
        }
        else if(angle == 90 || angle == 270) {
            width = parseInt(object.BOTTOMRIGHTY) - parseInt(object.TOPLEFTY);
            height = parseInt(object.BOTTOMRIGHTX) - parseInt(object.TOPLEFTX);
            left = parseInt(object.TOPLEFTX) + height/2;
            top = parseInt(object.TOPLEFTY) + width/2;

            if(angle==90) angle = 270;
            else angle = 90;
        }

        $.extend(addGenericObject(), {
            type:           "barcode",
            originX:        "center",
            originY:        "center",
            left:           scale(left),
            top:            scale(top),
            width:          scale(width),
            height:         scale(height),
            angle:          angle,
            fill:           "rgb(0,0,0)",
            strokeWidth:    1,
            opacity:        1,
            "src":          "{{{"+token+"}}}", // ????
            filters:        [],
            name:           token,
            strokeWidthNew: 0,
            cornerRadius:   0,
            strokeShow:     false,
            barcodeType:    symbology,
            lockUniScaling: false,
            textType:       "variable",
            text:           label
        });
    }

    function addQRcode(object) {
        var token = generateQrcodeToken(),
            textType = "fixed",
            text = "";

        if(object.PICPOS == "0" && object.ITEMFONTNAME != "") { //static
            template.card_data.push({
                type: "qrcode",
                token: token,
                data: [
                    {
                        "qrcode": object.ITEMFONTNAME
                    }
                ]
            });
        }
        else { //variable
            var data_num = parseInt(object.PICPOS)*-1-200;

            for(i=0; i<fieldData.length; i++) {
                if(fieldData[i].data_num == data_num) {
                    var label = removeFieldType(fieldData[i].data_name);

                    template.card_data.push({
                        type: "qrcode",
                        token: token,
                        data: [
                            {
                                "qrcode": "{{{"+removeUnsupportedCharacters(spaceToUnderscore(label))+"}}}"
                            }
                        ]
                    });

                    template.template_fields.push({
                        type:   "qrcode",
                        token:  removeUnsupportedCharacters(spaceToUnderscore(label)),
                        label:  label
                    });

                    textType = "variable";
                    text = label;
                }
            }
        }

        $.extend(addGenericObject(), {
            type:           "barcode",
            left:           scale(object.TOPLEFTX),
            top:            scale(object.TOPLEFTY),
            width:          scale(object.BOTTOMRIGHTX - object.TOPLEFTX),
            height:         scale(object.BOTTOMRIGHTY - object.TOPLEFTY),
            fill:           "rgb(0,0,0)",
            stroke:         "#425564",
            strokeWidth:    0,
            opacity:        1,
            "src":          "{{{"+token+"}}}", // itemFontName?
            filters:        [],
            name:           token,
            strokeWidthNew: 0,
            cornerRadius:   0,
            strokeShow:     false,
            barcodeType:    "qrcode",
            lockUniScaling: true,
            textType:       textType,
            text:           text
        });
    }

    function getFieldNameByID(id) {
        //console.log('id: '+id);
        //console.log(fieldData);

        for(var i=0; i<fieldData.length; i++) {
            if(parseInt(fieldData[i].data_num) == parseInt(id))
                return fieldData[i].data_name;
        }
    }

    function addMagstripe(magstripeData) {
        var magstripeFields = [];

        for(i=0; i<magstripeData.length; i++) {
            if(!getFieldNameByID(magstripeData[i].variable_id)) {
                addMessage("Magstripe variable #"+magstripeData[i].variable_id+" for the track #"+magstripeData[i].track_id+" doesn't exist","warning");
                continue;
            }

            var magstripeField = {};
            var label, token;

            label = removeFieldType(getFieldNameByID(magstripeData[i].variable_id));
            token = removeUnsupportedCharacters(spaceToUnderscore(label));

            magstripeField["track"+magstripeData[i].track_id] = "{{{"+token+"}}}";
            magstripeFields.push(magstripeField);

            template.template_fields.push({
                type:   "track"+magstripeData[i].track_id,
                token:  token,
                label:  label
            });
        }

        template.card_data.push({
            type: "magstripe",
            data: magstripeFields
        });

        if(getOptionValueByKey("orientation") == "landscape") {
            var width = cardWidth,
                height = Math.ceil((cardHeight * 0.33) / 2.125),
                top = Math.ceil((cardHeight * 0.223) / 2.125),
                left = 0;
        }
        else {
            var width = Math.ceil((cardHeight * 0.33) / 2.125),
                height = cardWidth,
                top = 0,
                left = Math.ceil((cardHeight * 0.223) / 2.125);

            addMessage("Magstripe card with a portrait orientation", "warning");
        }

        $.extend(addGenericObject(), {
            type:           "rect",
            left:           left,
            top:            top,
            width:          width,
            height:         height,
            fill:           'rgba(0,0,0,0)',
            evented:        false,
            selectable:     false,
            name:           'magStripe'
        });
    }

    function generateTextID() {
        var gotName = false,
            i = -1,
            textID;

        while(!gotName) {
            i++;
            textID = "text_"+i;
            gotName = true;

            for(i=0; i<templateData.objects.length; i++) {
                if (templateData.objects[i].textID == textID) {
                    gotName = false;
                }
            }
        }

        return textID;
    }

    function fontSize(size) {
        //var fontCoeff = 135/150;
        //return size*fontCoeff;
        return scaleVal((3.7*size)/10);
    }

    function addStaticText(object, isVariable) {
        var fontStyle, fontWeight, align, text, width, height, fitStyle, fieldName, fieldType, noClip = false;

        if(object.ITEMTEXT.indexOf("ï¿½")>-1)
            addMessage("Missing special character: "+object.ITEMTEXT, "warning");

        //TODO: check if there are templates with "transparency" off and set bg color

        if(isVariable) {
            var fieldNum = parseInt(object.ITEMTYPE)*-1-200,
                foundName = false;

            for(i=0; i<fieldData.length; i++) {
                if(fieldData[i].data_num == fieldNum) {
                    fieldName = removeFieldType(fieldData[i].data_name);
                    foundName = true;
                    fieldType = fieldData[i].data_type;
                    break;
                }
            }

            if(!foundName) {
                fieldName = object.ITEMTEXT;
                addMessage("Couldn't find the variable '"+fieldName+"' in the CARDDATA", "warning");
            }

            text = '{{{' + removeUnsupportedCharacters(spaceToUnderscore(fieldName)) + '}}}';

            if(fieldType=="text") {
                template.template_fields.push({
                    "type": "text",
                    "token": removeUnsupportedCharacters(spaceToUnderscore(fieldName)),
                    "label": fieldName
                });
            }
            else if(fieldType=="calculated_date") {
                addMessage("There's a calculated_date field ("+fieldName+")", "warning");

                template.template_fields.push({
                    "type": "calculated_date",
                    "token": removeUnsupportedCharacters(spaceToUnderscore(fieldName)),
                    "label": fieldName
                });

                template.card_data.push({
                    "type": "calculated_date",
                    "token": removeUnsupportedCharacters(spaceToUnderscore(fieldName)),
                    "data": [{
                        "plus": 0
                    }]
                });
            }

            if(object.ITEMFONTCROP == "0") {
                fitStyle = "none";
                noClip = true;
            }
            else if(object.ITEMFONTCROP == "1")
                fitStyle = "crop";
            else
                fitStyle = "resize";
        }
        else {
            fieldName = "";
            text = object.ITEMTEXT;
        }


        switch(object.ITEMFONTSTYLE) {
            case "0":
                fontStyle = "";
                fontWeight = "normal";
                break;
            case "1":
                fontStyle = "italic";
                fontWeight = "normal";
                break;
            case "2":
                fontStyle = "";
                fontWeight = "bold";
                break;
            case "3":
                fontStyle = "italic";
                fontWeight = "bold";
                break;
            default:
                break;
        };

        switch(object.ITEMFONTHALIGN) {
            case "0":
                align = "left";
                break;
            case "1":
                align = "center";
                break;
            case "2":
                align = "right";
                break;
            default:
                break;
        }

        width = scale(object.BOTTOMRIGHTX - object.TOPLEFTX);
        height = scale(object.BOTTOMRIGHTY - object.TOPLEFTY);

        var left = scale(object.TOPLEFTX),
            top = scale(object.TOPLEFTY),
            angle = parseInt(object.ITEMFONTORIENT),
            textID = generateTextID();

        var lineHeight = 1.1,
            fromTop = 0.1,
            fontSizeMod = 1;

        if(object.ITEMFONTNAME == "Open Sans" && fontWeight == "bold")
            object.ITEMFONTNAME = "Open Sans Extrabold";

        switch(object.ITEMFONTNAME) {
            case "Arial":
                lineHeight = 1; // was 1.15
                fromTop = 0.1;
                if (fontWeight == "bold") fontSizeMod = 1.03;
                break;
            case "Arial Black":
                lineHeight = 1;
                fontSizeMod = 0.85;
                fromTop = 0.2;
                break;
            case "Calibri":
                lineHeight = 1.1;
                fromTop = 0.1;
                break;
            case "Open Sans":
                lineHeight = 1.2;
                fromTop = 0.1;
                break;
            case "Open Sans Extrabold":
                fontSizeMod = 0.85;
                lineHeight = 1.22;
                fromTop = 0.2;
                break;
            case "IDAutomationHC39M":
                top = top + height * 0.56;
                height = height * 0.34;
                break;
            case "Centaur":
                fontSizeMod = 1.1;
                lineHeight = 0.95;
                fromTop = 0;
                break;
            default:
                break;
        }

        object.ITEMFONTHEIGHT = object.ITEMFONTHEIGHT*fontSizeMod;

        if(angle == 3) {
            angle = 0;
            addMessage("Please check the position of the text '"+text+"'", "warning");
        }

        if(angle == 1 || angle == 2) {
            var oldWidth = width, oldHeight = height;

            width = oldHeight;
            height = oldWidth;

            if(angle==2) {
                angle = 270;
                top += width;
                left += scale(fontSize(object.ITEMFONTHEIGHT))*fromTop;

                if(align == "left")
                    align = "right";
                else if(align == "right")
                    align = "left";
            }
            else {
                angle = 90;
                left += height;
                left -= scale(fontSize(object.ITEMFONTHEIGHT))*fromTop;
            }
        }
        else
            top += scale(fontSize(object.ITEMFONTHEIGHT))*fromTop;

        $.extend(addGenericObject(), {
            type:           "rect",
            left:           left,
            top:            top,
            width:          width,
            height:         height,
            fill:           "rgba(0,0,0,0)",
            stroke:         null,
            strokeWidth:    1,
            rx:             0,
            ry:             0,
            textID:         textID,
            name:           "textRect",
            angle:          angle,
            lockRotation:   false
        });

        var autoResize = false;

        if(isVariable && fitStyle=="resize") {
            autoResize = true;
            object.ITEMFONTHEIGHT = 1000;
        }

        var fontFamily = object.ITEMFONTNAME;

        $.extend(addGenericObject(), {
            type:           "static-text",
            left:           left,
            top:            top,
            width:          width,
            height:         height,
            fill:           intToRGB(object.ITEMFONTCOLOR),
            stroke:         null,
            strokeWidth:    1,
            opacity:        1,
            selectable:     false,
            evented:        false,
            text:           text,
            fieldName:      fieldName,
            fontSize:       scale(fontSize(object.ITEMFONTHEIGHT)),
            fontWeight:     fontWeight,
            fontStyle:      fontStyle,
            fontFamily:     fontFamily,
            lineHeight:     lineHeight,
            textDecoration: "",
            textAlign:      align,
            textBackgroundColor: "",
            styles:         {},
            align:          align,
            offsetLeft:     0,
            textID:         textID,
            autoResize:     autoResize,
            variable:       isVariable,
            noClip:         noClip,
            clipWidth:      width,
            clipHeight:     height,
            //clipTop:        -11,
            //clipLeft:       -28,
            angle:          angle
        });
    }

    function addLine(object) {
        var left, top, width, strokeWidth, angle, x1, x2;

        left = scale(object.TOPLEFTX);
        strokeWidth = scale(object.PLWIDTH)*2; // added *2
        top = scale(object.TOPLEFTY) - strokeWidth/2;

        if(object.ITEMTYPE == "1"){ // horizontal
            width = scale((object.BOTTOMRIGHTX - object.TOPLEFTX))/2;
            angle = 0;
            left -= strokeWidth;
        }
        else {
            width = scale((object.BOTTOMRIGHTY - object.TOPLEFTY))/2;
            angle = 90;
            top -= strokeWidth;
        }

        $.extend(addGenericObject(), {
            type:           "line",
            left:           left,
            top:            top,
            fill:           "rgb(0,0,0)",
            stroke:         intToRGB(object.PLCOLOR),
            strokeWidth:    strokeWidth,
            angle:          angle,
            x1:             -width,
            x2:             width,
            y1:             0,
            y2:             0,
            lockUniScaling: true
        });
    }

    function addRect(object) {
        var opacity, rx, ry;

        if(object.FILL == 0)
            opacity = 1;
        else if(object.FILL == 1)
            opacity = 0;
        else
            opacity = 0.5;

        if(object.ITEMTYPE=="4") {
            rx = 20;
            ry = 20;
        }
        else {
            rx = 0;
            ry = 0;
        }

        $.extend(addGenericObject(), {
            type:           "rect",
            left:           scale(object.TOPLEFTX),
            top:            scale(object.TOPLEFTY),
            width:          scale(object.BOTTOMRIGHTX - object.TOPLEFTX)-scale(object.PLWIDTH)*2,
            height:         scale(object.BOTTOMRIGHTY - object.TOPLEFTY)-scale(object.PLWIDTH)*2,
            fill:           intToRGB(object.BRUSHCOLOR, opacity),
            stroke:         intToRGB(object.PLCOLOR),
            strokeWidth:    scale(object.PLWIDTH)*2,
            rx:             rx,
            ry:             ry
        });
    }

    function addEllipse(object) {
        //"rx":137.71388233670996,"ry":68.50517778793107}
        var opacity, width, height, rx, ry;

        if(object.FILL == 0)
            opacity = 1;
        else if(object.FILL == 1)
            opacity = 0;
        else
            opacity = 0.5;

        width = scale(object.BOTTOMRIGHTX - object.TOPLEFTX);
        height = scale(object.BOTTOMRIGHTY - object.TOPLEFTY);
        rx = width/2;
        ry = height/2;

        $.extend(addGenericObject(), {
            type:           "ellipse",
            left:           scale(object.TOPLEFTX),
            top:            scale(object.TOPLEFTY),
            width:          width,
            height:         height,
            fill:           intToRGB(object.BRUSHCOLOR, opacity),
            stroke:         intToRGB(object.PLCOLOR),
            strokeWidth:    scale(object.PLWIDTH),
            rx:             rx,
            ry:             ry
        });
    }

    function addSlotPunch() {
        var slot_punch = getOptionValueByKey("slot_punch"),
            orientation = getOptionValueByKey("orientation");

        if(slot_punch != "long" && slot_punch != "short") return;

        if(orientation=="landscape" && slot_punch == "long") {
            var width = 148.4,
                height = 35.4,
                left = 431.8,
                top = 66.4;
        }
        else if(orientation=="landscape" && slot_punch == "short") {
            var width = 35.4,
                height = 148.4,
                left = 66.4,
                top = 245.8;
        }
        else if(orientation=="portrait" && slot_punch == "long") {
            var width = 35.4,
                height = 148.4,
                left = 66.4,
                top = 431.8;
        }
        else if(orientation=="portrait" && slot_punch == "short") {
            var width = 148.4,
                height = 35.4,
                left = 245.8,
                top = 66.4;
        }

        $.extend(addGenericObject(), {
            type:           "rect",
            left:           left,
            top:            top,
            width:          width,
            height:         height,
            fill:           'rgba(0,0,0,0)',
            stroke:         'rgba(0,0,0,0)',
            strokeWidth:    2.2144420131291027,
            rx:             10,
            ry:             10,
            evented:        false,
            selectable:     false,
            name:           'slotPunch'
        });
    }

    function spaceToUnderscore(string) {
        return string;
        //return string.replace(/ /g,"_");
    }

    function base64toBlob(dataURI, callback) {
        // convert base64 to raw binary data held in a string
        // doesn't handle URLEncoded DataURIs - see SO answer #6850276 for code that does this
        var byteString = atob(dataURI.split(',')[1]);

        // separate out the mime component
        var mimeString = dataURI.split(',')[0].split(':')[1].split(';')[0]

        // write the bytes of the string to an ArrayBuffer
        var ab = new ArrayBuffer(byteString.length);
        var ia = new Uint8Array(ab);
        for (var i = 0; i < byteString.length; i++) {
            ia[i] = byteString.charCodeAt(i);
        }

        // write the ArrayBuffer to a blob, and you're done
        var bb = new Blob([ab], { type: 'image/jpeg' });
        return bb;
    }

    function blobToFile(theBlob, fileName){
        theBlob.lastModifiedDate = new Date();
        theBlob.name = fileName;
        return theBlob;
    }

    function templateDataJSON(xml) {
        template.front_data = convert(xml, 0);
        template.back_data = convert(xml, 1);

        swapImagesToBase64(prepareTemplateForPreview(template.front_data), true);
        swapImagesToBase64(prepareTemplateForPreview(template.back_data), false);

        //generateTemplatePreviewBase64(JSON.stringify(template.front_data), JSON.stringify(template.back_data));

        return JSON.stringify(template);
    }

    function templateReadCardData(_CARD, _CARDDATA) {
        template.id = _CARDDATA.CARD_REF_NUM;
        template.organization_id = _CARDDATA.COMPANY_NO;
        template.name = _CARDDATA.CARD_LIST_DES;
        template.card_type_id = _CARD[0].CARD_TYPE;

        var sides = "single",
            orientation = "landscape";

        if(_CARD[0].ORIENT != 0)
            orientation = "portrait";

        for(var i=0; i<_CARD.length; i++) {
            if(_CARD[i].SIDE == 1) {
                sides = "double";
                break;
            }
        }

        setOptionValueByKey("orientation", orientation);
        setOptionValueByKey("sides", sides);
    }

    function templateReadFieldData(_CARDDATA) {
        fieldData = [];

        for (var property in _CARDDATA) {
            //if (_CARDDATA.hasOwnProperty(property) && _CARDDATA[property] && _CARDDATA[property] != "~0~" && _CARDDATA[property] != "~1~" && property.substring(0, 10) == "DATA_NAME_") {
            if (_CARDDATA.hasOwnProperty(property) && _CARDDATA[property] && property.substring(0, 10) == "DATA_NAME_") {
                if(_CARDDATA[property] == "~0~" || _CARDDATA[property] == "~1~" ) {
                    fieldData.push({
                        data_num: parseInt(property.substring(10)),
                        data_name: "~placeholder~",
                        data_type: "text"
                    });
                }
                else {
                    var name = _CARDDATA[property];
                    if (name.slice(-1) != "~") name = name + "~0~";

                    fieldData.push({
                        data_num: parseInt(property.substring(10)),
                        data_name: name,
                        data_type: getFieldTypeFromName(name)
                    });
                }
            }
        }

        // Remove empty fields from the end of the array
        for (var i=fieldData.length-1; i>-1; i--) {
            if(fieldData[i].data_name != "~placeholder~")
                break;
            else
                fieldData.splice(i, 1);
        }
    }

    function rearrangeTextVariables(template_fields) {
        for(var i=0; i<template_fields.length; i++) {
            if(template_fields[i].type!="text") continue;

            for(var z=0; z<fieldData.length; z++) {
                if(!fieldData[z].data_name) continue;

                if(template_fields[i].label == removeFieldType(fieldData[z].data_name)) {
                    fieldData[z].template_field = template_fields[i];
                    template_fields[i] = false;
                }
            }
        }

        var template_fields_new = [];

        for(var i=0; i<fieldData.length; i++) {
            if(!fieldData[i].data_name) continue;

            if(fieldData[i].template_field)
                template_fields_new.push(fieldData[i].template_field);
            else {
                var fieldType = "text";
                if(fieldData[i].data_type) fieldType = fieldData[i].data_type;

                template_fields_new.push({
                    type: fieldType,
                    token: removeUnsupportedCharacters(spaceToUnderscore(removeFieldType(fieldData[i].data_name))),
                    label: removeFieldType(fieldData[i].data_name)
                });
            }
        }

        for(var i=0; i<template_fields.length; i++) {
            if(template_fields[i])
                template_fields_new.push(template_fields[i]);
        }

        return template_fields_new;
    }

    function removeRepeatingImageVariables(template_fields) {
        var template_fields_new = [], template_image_fields = [];

        for(var i=0; i<template_fields.length; i++) {
            if(template_fields[i].type == "image") {
                var shouldAdd = true;

                for(var z=0; z<template_image_fields.length; z++) {
                    if(template_image_fields[z].token == template_fields[i].token) {
                        if(template_image_fields[z].dimensions.width < template_fields[i].dimensions.width) {
                            template_image_fields[z].dimensions.width = template_fields[i].dimensions.width;
                            template_image_fields[z].dimensions.height = template_fields[i].dimensions.height;
                        }

                        shouldAdd = false;
                    }
                }

                if(shouldAdd)
                    template_image_fields.push(template_fields[i]);
            }
            else
                template_fields_new.push(template_fields[i]);
        }

        for(var i=0; i<template_image_fields.length; i++) {
            template_fields_new.push(template_image_fields[i]);
        }

        return template_fields_new;
    }

    function removeRepeatingTextVariables(template_fields) {
        // 1. remove text, barcode etc fields with the same name
        // 2. on load add barcode var by analyzing card data
        // 3. remove on save again

        var template_fields_new = [];
        var noPlaceholders = true;

        for(var i=0; i<template_fields.length; i++) {
            if(template_fields[i].type == "image") {
                template_fields_new.push(template_fields[i]);
                continue;
            }

            var isUsed = false;
            for(var z=0; z<template_fields_new.length; z++) {
                if(template_fields[i].label != "~placeholder~" && template_fields[i].token == template_fields_new[z].token)
                    isUsed = true;
            }

            if(template_fields[i].label == "~placeholder~") {
                noPlaceholders = false;

                template_fields[i] = {
                    type: "placeholder",
                    token: "PlaceHolder",
                    label: "PlaceHolder"
                };
            }

            if(!isUsed)
                template_fields_new.push(template_fields[i]);
        }

        if(!noPlaceholders) addMessage("There are placeholder fields in this template", "warning");

        return template_fields_new;
    }

    function removeFieldType(name) {
        name = name.replace(/~0~|~1~|~2~|~3~|~4~|~5~|~6~/gi, "");
        return name;
    }

    function getFieldTypeFromName(name) {
        var newName = name.slice(-3);

        switch(newName) {
            case "~0~":
                return "text";
            case "~1~":
                return "selectbox";
            case "~2~":
                addMessage("There's a print_counter field ("+name+")", "warning");
                return "print_counter";
            case "~3~":
                addMessage("There's a global_counter field ("+name+")", "warning");
                return "global_counter";
            case "~4~":
                addMessage("There's a concatenated field ("+name+")", "warning");
                return "concatenated";
            case "~5~":
                //addMessage("There's a calculated_date field ("+name+")", "warning");
                return "calculated_date";
            case "~6~":
                return "checkbox";
            default:
                addMessage("This template might contain a field ("+name+") with an unsupported type", "warning");
                return "text";
        }
    }

    function fixFieldselFields(template_fields, fieldsel) {
        //get field name from data_num in fieldData
        //find template field with this name
        //change type
        //add options
        for(i=0; i<fieldsel.length; i++) {
            var dataNum = fieldsel[i].DATA_NUM,
                numOfOps = fieldsel[i].NUM_OF_OPS,
                fieldToken = false,
                options = [],
                type = "text";

            if(numOfOps===null) numOfOps = 2;

            // get the token of the template field that needs to be replaced
            for(z=0; z<fieldData.length; z++) {
                if(fieldData[z].data_num==dataNum) {
                    type = getFieldTypeFromName(fieldData[z].data_name);
                    fieldToken = removeUnsupportedCharacters(spaceToUnderscore(removeFieldType(fieldData[z].data_name))); //get type here from ~1~, ~6~?
                }
            }

            if(!fieldToken || type == "text") {
                addMessage("There might be a problem with a fieldsel field #"+dataNum+" (broken token)", "warning");
                continue;
            }

            // get options array
            for (var property in fieldsel[i]) {
                if(numOfOps == 0) break;

                if (fieldsel[i].hasOwnProperty(property) && property.substring(0, 6) == "OPTION") {
                    var value = fieldsel[i][property];
                    if(!value) value = "";
                    options.push(value);
                    numOfOps--;
                }
            }

            if(options.length == 0) {
                addMessage("There might be a problem with a fieldsel field #"+dataNum+" (0 options)", "warning");
                continue;
            }

            // find and fix the template field
            for(z=0; z<template_fields.length; z++) {
                //if(template_fields[z].type == "text" && template_fields[z].token == fieldToken) {
                if(template_fields[z].token == fieldToken) {
                    template_fields[z].type = type;

                    if(type=="checkbox") {
                        template_fields[z].checked = options[0];
                        template_fields[z].unchecked = options[1];
                    }
                    else if(type=="selectbox")
                        template_fields[z].options = options;
                    else
                        addMessage("There might be a problem with a fieldsel field: "+fieldToken+" (type not supported)", "warning");
                }
            }
        }

        return template_fields;
    }

    function convert(_CARD, side) {
        var shouldAddMagstripe = false,
            magstripeData = [];

        templateData = JSON.parse(cleanTemplate);

        if(getOptionValueByKey("orientation")=="portrait") {
            templateData.backgroundImage.height = cardWidth;
            templateData.backgroundImage.width = cardHeight;
        }
        else {
            templateData.backgroundImage.height = cardHeight;
            templateData.backgroundImage.width = cardWidth;
        }

        for(var i=0; i<_CARD.length; i++)
        {
            if(parseInt(_CARD[i].JOB_NUMBER)>0) continue;

            if(side == 1 && (_CARD[i].REF == "-1" || _CARD[i].REF == "-2" || _CARD[i].REF == "-3") && mag_stripe) {
                shouldAddMagstripe = true;

                if(parseInt(_CARD[i].ITEMTYPE) != -200) {
                    magstripeData.push({
                        track_id: -1 * parseInt(_CARD[i].REF),
                        variable_id: -1 * parseInt(_CARD[i].ITEMTYPE) - 200
                    });
                }

                continue;
            }
            else if(parseInt(_CARD[i].SIDE) != side) continue;

            // convert barcode with a type "qrcode" into a real qrcode object
            if(_CARD[i].ITEMTYPE=="9" && _CARD[i].ITEMFONTSTYLE=="23") _CARD[i].ITEMTYPE = "14";

            if(_CARD[i].ITEMTYPE=="7" && (_CARD[i].ITEMTEXT=="" || _CARD[i].GRAPHIC=="")) continue;

            switch(_CARD[i].ITEMTYPE) {
                case "1":       // Horizontal Line
                case "8":       // Vertical Line
                    addLine(_CARD[i]);
                    break;
                case "2":       // Rectangle
                case "4":       // Rounded Rectangle
                    addRect(_CARD[i]);
                    break;
                case "3":       // Ellipse
                    addEllipse(_CARD[i]);
                    break;
                case "5":       // Static Text
                    addStaticText(_CARD[i], false);
                    break;
                case "7":       // Static Image
                    addImage(_CARD[i]);
                    break;
                case "10":      // Photo
                case "11":      // Signature
                case "12":      // Variable Image
                    addVarImage(_CARD[i]);
                    break;
                case "9":       // Barcode
                    addBarcode(_CARD[i]);
                    break;
                case "14":      // QR code
                    addQRcode(_CARD[i]);
                    break;
                default:
                    if(_CARD[i].ITEMTYPE < 0 && _CARD[i].ITEMTYPE != -200)    // Variable Text
                        addStaticText(_CARD[i], true);
                    break;
                // 6?
            }
        }

        addSlotPunch();

        if(shouldAddMagstripe)
            addMagstripe(magstripeData);

        return templateData;
    }

    function resetTemplate(){
        template = false;
        template = $.extend(true,{},basicTemplate);
        mag_stripe = false;
    }

    function objectParamsToStrings(object) {
        for (var property in object) {
            if (object.hasOwnProperty(property) && property != "GRAPHIC" && object[property] !== null) {
                object[property] = object[property].toString();
            }
        }

        return object;
    }

    function arrayObjectsParamsToStrings(array) {
        if(!$.isArray(array)) return objectParamsToStrings(array);

        for(i=0; i<array.length; i++) {
            array[i] = objectParamsToStrings(array[i]);
        }

        return array;
    }

    function colorToGrayscale(color) {
        return new fabric.Color(color).toGrayscale().toRgba();
    }

    function makeObjectsGrayscale(back_data) {
        for(i=0; i<back_data.objects.length; i++) {
            if (back_data.objects[i].type == "image" || back_data.objects[i].type == "variable-image") {
                back_data.objects[i].filters[2] = new fabric.Image.filters.Grayscale();
                //object.applyFilters();
            }

            if (back_data.objects[i].fill)
                back_data.objects[i].fill = colorToGrayscale(back_data.objects[i].fill);
            if (back_data.objects[i].stroke)
                back_data.objects[i].stroke = colorToGrayscale(back_data.objects[i].stroke);
        }

        back_data.backgroundImage.filters[0] = new fabric.Image.filters.Grayscale();

        return back_data;
    }

    function convertTemplate(_CARD, _CARDDATA, options) {
        base64Images = [];

        _CARD = arrayObjectsParamsToStrings(_CARD);
        _CARDDATA = arrayObjectsParamsToStrings(_CARDDATA);

        if(parseInt(_CARDDATA[0].COMPANY_NO) == 0 && _CARDDATA.length > 1) _CARDDATA[0] = _CARDDATA[1];

        resetTemplate();
        templateReadCardData(_CARD, _CARDDATA[0]);
        templateReadFieldData(_CARDDATA[0]);

        /////////// Set slot punch
        if(options.slot_punch == true) {
            if(getOptionValueByKey("orientation")=="portrait") {
                setOptionValueByKey("slot_punch", "short");
            }
            else {
                setOptionValueByKey("slot_punch", "long");
            }
        }
        else {
            setOptionValueByKey("slot_punch", "none");
        }

        if(options.mag_stripe == true)
            mag_stripe = true;
        else
            mag_stripe = false;

        /////////// Set back side color
        var isOneSide = true;

        for(var i=0; i<_CARD.length; i++) {
            if (parseInt(_CARD[i].SIDE) == 1) {
                isOneSide = false;
                break;
            };
        }

        if(isOneSide)
            setOptionValueByKey("color", "color");
        else if(options.color == true)
            setOptionValueByKey("color", "colorcolor");
        else
            setOptionValueByKey("color", "colorblack");
        ///////////

        template.front_data = convert(_CARD, 0);
        template.back_data = convert(_CARD, 1);

        if(getOptionValueByKey("color")=="colorblack") {
            template.back_data = makeObjectsGrayscale(template.back_data);
        }

        template.template_fields = rearrangeTextVariables(template.template_fields);
        template.template_fields = removeRepeatingImageVariables(template.template_fields);
        template.template_fields = removeRepeatingTextVariables(template.template_fields);

        if(options.fieldsel && options.fieldsel.length>0) {
            template.template_fields = fixFieldselFields(template.template_fields, options.fieldsel);
            addMessage("This template contains fieldsel fields", "warning");
        }

        var returnTemplate = {};
        returnTemplate.template = $.extend(true,{},template);

        returnTemplate.images = base64Images;

        return returnTemplate;
    }


// Known problems with templates:
// 6274 : rotated barcode // OK
// 6321 : logo doesn't fit in - fixed; weird back side??
// 1477 : photo and/or bg out of position // OK
// 2635 : no border - fixed;
// 1434 : b&w filter - fixed; check remove green filter;
// add support for <0 position? - fixed
// add warning if same image multiple times, at least once with a filter RemoveWhite

// 6968 : magstripe with no variables. weird small font? - font problem. ok when changed to Arial// load fonts first, then load?
// 3946 : magstripe with data - wrong ID's of variables // OK
// 3629 : test magstripe on this one - everything works here // OK

// 1122 : itemtype = -327???
// 3064 : vertical magstripe, check text on the back side

// 3996 : vertical magstripe, broken text on the back side

// 6975 : red transparency doesn't always work? // 0 barcode
// 6298 : check font // 90 barcode
// 2 : the only template with 180 barcode
// 6705 : back side completely messed up (vertical text?) // barcode 270
// 6501 : same template as 6705 = 3814 = 6307 = 4366 = ...?
// 3913 : barcode 270

// TODO: transparency filter doesn't work sometimes - possibly when an images takes too much time to load? Only affects the previews, should still work ok in the editor.

// TODO: in the editor - analyze fonts after loading a template, add missing fonts to the list

// TODO: show other types of text variables in the variables window

// VAR TYPES: 0 - normal, 1 - select, 2 - print counter, 3 - global counter, 4 - concatenated, 5 - calculated date, 6 - checkbox
// radiobox??
// 0, 1, 6 - ok
// 2 - 3958,
// 3 - none,
// 4 - 363, 2482 (both are weird, 2482 is empty, 363 only has it in the row with COMPANY_NO==0)
// 5 - 159, 324, 325, 333, 459, 509, 579, 1947
//6627 is broken!