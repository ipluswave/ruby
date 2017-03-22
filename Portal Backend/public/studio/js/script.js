(function() {
    var clone = fabric.util.object.clone;
    fabric.Textbox = fabric.util.createClass(fabric.IText, fabric.Observable,  {
        /**
         * Type of an object
         * @type String
         * @default
         */
        type: 'textbox',

        /**
         * Constructor
         * @param {String} text Text string
         * @param {Object} [options] Options object
         * @return {fabric.Textbox} thisArg
         */
        initialize: function(text, options) {
            this.styles = options ? (options.styles || { }) : { };
            options.originY = "top";
            this.callSuper('initialize', text, options);
        },
        /**
         * Break the text accordingly to the width of Textbox. Based on the code of Darren Nolan (@darrennolan)
         * @method _wrapText
         * @param {CanvasRenderingContext2D} ctx Context to render on
         * @param {String} Text to wrap
         * @return {Array} Array with the lines of the text
         */
        _wrapText: function (ctx, text) {
            var scaleX = (this.originalScales ? this.originalScales[0] : this.scaleX);
            var maxWidth = (this.width * scaleX),
                lines = text.split(this._reNewline),
                wrapped_text = [];

            var maximum=0;

            for (var l = 0; l < lines.length; l++) {
                var line = "";
                var words = lines[l].split(" ");
                for (var w = 0; w < words.length; w++) {
                    var testLine = line + words[w] + " ";
                    var metrics = ctx.measureText(testLine);
                    var testWidth = metrics.width;
                    if (testWidth > (maxWidth )) {
                        wrapped_text.push(line);
                        line = words[w] + " ";
                    } else {
                        line = testLine;
                        maximum = Math.max(testWidth, maximum);
                    }
                }
                wrapped_text.push(line.trim());
            }

            return wrapped_text;
        },
        /**
         * @private
         * @param {CanvasRenderingContext2D} ctx Context to render on
         */
        _renderViaNative: function(ctx) {

            this._setTextStyles(ctx);

            //this.fontSize = 16;
            this.width = 200;
            this.height = 100;

            var coef = this.originX=="left"? 1:(this.originX=="right"?-1:0);
            //ctx.translate(this.left+coef*this.width/2, this.top+this.height/(2*this.lineHeight));
            var textLines = this._wrapText(ctx, this.text);

            var txtH = this._getTextHeight(ctx, textLines);
            var lHeight = this._getTextHeight(ctx, ["A"]);

            if(txtH>this.height*this.scaleY){
                var lcount = (txtH - this.height*this.scaleY) / (lHeight);
                for(var ln=0;ln<lcount; ln++) textLines.pop();
            }

            this.clipTo && fabric.util.clipContext(this, ctx);

            this._renderTextBackground(ctx, textLines);
            this._translateForTextAlign(ctx);
            this._renderText(ctx, textLines);

            if (this.textAlign !== 'left' && this.textAlign !== 'justify') {
                ctx.restore();
            }

            this._renderTextDecoration(ctx, textLines);
            this.clipTo && ctx.restore();
            this._setBoundaries(ctx, textLines);
            this._totalLineHeight = 0;
        },
        /**
         * Returns object representation of an instance
         * @method toObject
         * @param {Array} [propertiesToInclude] Any properties that you might want to additionally include in the output
         * @return {Object} object representation of an instance
         */
        toObject: function(propertiesToInclude) {
            return fabric.util.object.extend(this.callSuper('toObject', propertiesToInclude), {
                styles: clone(this.styles)
            });
        }
    });
    /**
     * Returns fabric.Textbox instance from an object representation
     * @static
     * @memberOf fabric.Textbox
     * @param {Object} object Object to create an instance from
     * @return {fabric.Textbox} instance of fabric.Textbox
     */
    fabric.Textbox.fromObject = function(object) {
        return new fabric.Textbox(object.text, clone(object));
    };
    /**
     * Contains all fabric.Textbox objects that have been created
     * @static
     * @memberof fabric.Textbox
     * @type Array
     */
    fabric.Textbox.instances = [ ];
})();