//////////////////////////////// CLASS EXTENSIONS ////////////////////////////////

// New IText
// FIX COPY PASTE FOR GROUPS

// Static Text

fabric.StaticText = fabric.util.createClass(fabric.IText, {

    type: 'static-text',

    initialize: function(element, options) {
        this.callSuper('initialize', element, options);
        options && this.set('align', options.align || "left");
        options && this.set('offsetLeft', options.offsetLeft || 0);
        options && this.set('textID', options.textID || "");
        options && this.set('clipLeft', options.clipLeft || 0);
        options && this.set('clipTop', options.clipTop || 0);
        options && this.set('clipWidth', options.clipWidth || 0);
        options && this.set('clipHeight', options.clipHeight || 0);
        options && this.set('evented', options.evented || false);
        options && this.set('selectable', options.selectable || false);
        options && this.set('variable', options.variable || "");
        options && this.set('autoResize', options.autoResize || false);
    },

    toObject: function() {
        return fabric.util.object.extend(this.callSuper('toObject'), {
            align: this.align,
            offsetLeft: this.offsetLeft,
            textID: this.textID,
            clipLeft: this.clipLeft,
            clipTop: this.clipTop,
            clipWidth: this.clipWidth,
            clipHeight: this.clipHeight,
            evented: this.evented,
            selectable: this.selectable,
            variable: this.variable,
            autoResize: this.autoResize
        });
    }
});

fabric.StaticText.fromObject = function(object) {
    return new fabric.StaticText(object.text, object);
};

fabric.StaticText.async = false;

// Image
// I've edited the Image object in the fabric.js and added:
// strokeWidth = 0
// strokeWidthNew || 0
// strokeShow || false
// cornerRadius || 0
// and also changed _render

// Variable Image

fabric.VariableImage = fabric.util.createClass(fabric.Image, {

    type: 'variable-image',

    initialize: function(element, options) {
        this.callSuper('initialize', element, options);
        options && this.set('name', options.name || '');
        options && this.set('scaleType', options.scaleType || 'stretch');
    },

    toObject: function() {
        return fabric.util.object.extend(this.callSuper('toObject'), { src: '{{{'+this.name+'}}}', name: this.name, scaleType: this.scaleType });
    },

    _render: function(ctx) {
        this.callSuper('_render', ctx);

        ctx.font = '20px Arial';
        ctx.fillStyle = 'white';
        ctx.fillText(this.name, -this.width/2 + 10, -this.height/2 + 25);
    }
});

fabric.VariableImage.fromObject = function(object, callback) {
    fabric.util.loadImage(object.src, function(img) {
        fabric.VariableImage.prototype._initFilters.call(object, object, function(filters) {
            object.filters = filters || [ ];
            var instance = new fabric.VariableImage(img, object);
            callback && callback(instance);
        });
    }, null, object.crossOrigin);
};

fabric.VariableImage.async = true;

// Barcode

fabric.Barcode = fabric.util.createClass(fabric.Image, {
    type: 'barcode',

    initialize: function(element, options) {
        this.callSuper('initialize', element, options);
        options && this.set('name', options.name || '');
        options && this.set('barcodeType', options.barcodeType || 'code39');
        options && this.set('textType', options.textType || 'fixed');
        options && this.set('text', options.text || '');
    },

    toObject: function() {
        return fabric.util.object.extend(this.callSuper('toObject'), { name: this.name, barcodeType: this.barcodeType, lockUniScaling: this.lockUniScaling, textType: this.textType, text: this.text });
    }
});

fabric.Barcode.fromObject = function (object, callback) {
    fabric.util.loadImage(object.src, function (img) {
        var oImg = new fabric.Barcode(img);
        oImg._initConfig(object);
        callback(oImg);
    });
};

fabric.Barcode.async = true;

// Group objects with shift+click
// fabric.util.object.extend(fabric.Canvas.prototype, {
//     _shouldGroup: function (e, target) {
//         var activeObject = this.getActiveObject();
// 
//         return shiftPressed &&
//         (this.getActiveGroup() || (activeObject && activeObject !== target))
//         && this.selection;
//     },
//     _shouldClearSelection: function (e, target) {
//         var activeGroup = this.getActiveGroup(),
//             activeObject = this.getActiveObject();
// 
//         return (
//         !target
//         ||
//         (target &&
//         activeGroup &&
//         !activeGroup.contains(target) &&
//         activeGroup !== target &&
//         !shiftPressed)
//         ||
//         (target && !target.evented)
//         ||
//         (target &&
//         !target.selectable &&
//         activeObject &&
//         activeObject !== target)
//         );
//     }
// });
// 
// // Canvas settings
// fabric.Object.prototype.set({
//     transparentCorners: false,
//     cornerColor: 'rgba(102,153,255,0.5)',
//     cornerSize: 10,
//     borderScaleFactor: 0.5
// });

////////////////////////////////////////////////////////////////////////////


function updateFonts(data) {
    // add default fonts
    // font from a browser добавляются в array
    // font browser - scan a folder with ttfs

    fonts = data;
    // fonts.push({name: 'Arial'}); // del later

    for(var i=0; i<fonts.length; i++) {
        if($.fontAvailable(fonts[i].name))
            continue;

        if(fonts[i].url && fonts[i].url != "") {
            $('<style type="text/css">@import url("' + fonts[i].url + '")</style>')
                    .appendTo("head");
        }
        else if(fonts[i].files && fonts[i].files.length > 0) {
            for(var z=0; z<fonts[i].files.length; z++) { // need to update this later so that eot is always first
                $('<style type="text/css">@font-face {font-family: '+fonts[i].name+'; src: url('+fonts[i].files[z]+');}</style>')
                        .appendTo("head");
            }
        }
    }

}

function resizeAllTextObjects(canvas) {
    canvas.forEachObject(function(object) {
        resizeObject2(object);
    });
}

function resizeObject2(object) {
    if(object.get('type')=="variable-text" || object.get('type')=="static-text") {
        object.scale(1);
        if(object.width > object.maxWidth) {
            object.scaleToWidth(object.maxWidth);
        }
    }
}

function makeAllObjectsUnselectable(canvas) {
    canvas.deactivateAllWithDispatch().renderAll();
    canvas.forEachObject(function(object){ object.selectable = false });
}

function showSlotPunchMagStripe(canvas, isPreview) {
  var has_filters = false;
  canvas.forEachObject(function (object) {
      if(isPreview && (object.get('name') == 'magStripe' || object.get('name') == 'slotPunch')) {
          object.fill = "rgba(f, f, f, f)";
      }
  });
  return has_filters;
}

function updateAlignOfAllObjects(canvas) {
    canvas.forEachObject(function(object){
        updateAlign(object);
    });
    canvas.renderAll();
}

function updateAlign(object) {
    if(object.get('type') == "static-text" || object.get('type')=="variable-text")
        object.setTextAlign(object.align);

    if(object.get('type')!="variable-text") return;

    object.left = object.left - object.offsetLeft; // move the object to the default position
    object.offsetLeft = 0;

    if(object.width > object.maxWidth) return;

    if(object.align=="right") {
        object.offsetLeft = object.maxWidth - object.width;
        object.left = object.left + object.offsetLeft;
    }
    else if(object.align=="center") {
        object.offsetLeft = Math.ceil((object.maxWidth - object.width)/2);
        object.left = object.left + object.offsetLeft;
    }

    object.setCoords();
}

function prepareTemplateForLoading(data) {
    if(!data) return;

    var dataScaled = scaleObjects(data.objects, data.backgroundImage, false);

    data.objects = dataScaled.objects;
    data.backgroundImage = dataScaled.background;

    return JSON.stringify(data);
}

// API
function scale(int, coeff) {
    var newFloat = int*coeff,
            newInt = Math.ceil(newFloat);

    return newFloat;
}

function scaleObjects(objects, background, scaleUp) {
    //TODO: templateFields images?

    // check if scaling needed by checking the bg size
    if((scaleUp && (background.width == 1012 || background.height == 1012)) || (!scaleUp && (background.width == 457 || background.height == 457)))
        return {objects: objects, background: background};

    var coeff = 1;

    if(scaleUp)
        coeff = 1012 / 457;
    else
        coeff = 457 / 1012;

    for(i=0; i<objects.length; i++) {
        if(objects[i].left)
            objects[i].left = scale(objects[i].left, coeff);
        if(objects[i].top)
            objects[i].top = scale(objects[i].top, coeff);
        if(objects[i].width)
            objects[i].width = scale(objects[i].width, coeff);
        if(objects[i].height)
            objects[i].height = scale(objects[i].height, coeff);
        if(objects[i].strokeWidth)
            objects[i].strokeWidth = scale(objects[i].strokeWidth, coeff);
        if(objects[i].strokeWidthNew)
            objects[i].strokeWidthNew = scale(objects[i].strokeWidthNew, coeff);
        if(objects[i].cornerRadius)
            objects[i].cornerRadius = scale(objects[i].cornerRadius, coeff);
        if(objects[i].fontSize)
            objects[i].fontSize = scale(objects[i].fontSize, coeff);
        if(objects[i].fontSizeOriginal)
            objects[i].fontSizeOriginal = scale(objects[i].fontSizeOriginal, coeff);
        if(objects[i].x1)
            objects[i].x1 = scale(objects[i].x1, coeff);
        if(objects[i].x2)
            objects[i].x2 = scale(objects[i].x2, coeff);
        if(objects[i].clipWidth)
            objects[i].clipWidth = scale(objects[i].clipWidth, coeff);
        if(objects[i].clipHeight)
            objects[i].clipHeight = scale(objects[i].clipHeight, coeff);
        if(objects[i].rx)
            objects[i].rx = scale(objects[i].rx, coeff);
        if(objects[i].ry)
            objects[i].ry = scale(objects[i].ry, coeff);

        // TODO: check other rects like slotPunch
        /*
        if(objects[i].scaleX && objects[i].type=="rect")
            objects[i].scaleX = scale(objects[i].scaleX, coeff);
        if(objects[i].scaleY && objects[i].type=="rect")
            objects[i].scaleY = scale(objects[i].scaleY, coeff);*/
    }

    if(scaleUp) {
        if(background.width>background.height) {
            background.width = 1012;
            background.height = 638;
        }
        else {
            background.width = 638;
            background.height = 1012;
        }
    }
    else {
        if(background.width>background.height) {
            background.width = 457;
            background.height = 288;
        }
        else {
            background.width = 288;
            background.height = 457;
        }
    }

    return {objects: objects, background: background};
}

function isTextRect(object) {
    if(object.type == "rect" && object.name == "textRect")
        return true;
    else
        return false;
}

function getTextByTextID(canvas, textID) {
    var text = false;

    canvas.forEachObject(function (object) {
        if ((object.type == "static-text" || object.type == "variable-text") && object.textID == textID) {
            text = object;
        }
    });

    return text;
}

function getRectByTextID(canvas, textID) {
    var rect = false;

    canvas.forEachObject(function (object) {
        if (isTextRect(object) && object.textID == textID) {
            rect = object;
        }
    });

    return rect;
}

function recalcTextPosition(canvas, textID, groupLeft, groupTop) {
    var text = getTextByTextID(canvas, textID),
            rect = getRectByTextID(canvas, textID),
            top, left, width;

    groupLeft = groupLeft || 0;
    groupTop = groupTop || 0;

    canvas.renderAll();

    var realTextWidth = text.width*text.scaleX;

    if(groupLeft != 0 || groupTop != 0) {
        left = groupLeft;
        top = groupTop;
    }
    else {
        top = rect.top;
        left = rect.left;
    }

    if (rect.width > realTextWidth && text.align != "left") {
        width = text.width;

        if(text.align == "center")
            left = left + (rect.width - realTextWidth)/2;
        else if(text.align == "right")
            left = left + (rect.width - realTextWidth);
    }
    else {
        left = left;
        width = rect.width;
    }

    text.set({
        left:   left,
        top:    top,
        originX: rect.originX,
        originY: rect.originY,
        angle: rect.angle,
        width: width,
        height: rect.height
    });

    recalcTextClipping(canvas, textID);
}

function recalcTextClipping(canvas, textID) {
    var text = getTextByTextID(canvas, textID),
            rect = getRectByTextID(canvas, textID);
    text.set({
        clipLeft: -text.width / 2,
        clipTop: -text.height / 2,
        clipWidth: rect.width,
        clipHeight: rect.height
    });
}

function onObjectAdded(options) {
    if (options.target.type == "static-text") {
        recalcTextPosition(options.target.canvas, options.target.textID);
    }
}
