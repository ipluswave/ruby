var config = {
        apiURL:       '/api/v1/',
        varIMG:       'img/var-img.png',
        barcodeIMG:   {
            qrcode: 'img/barcodes/img-barcode-qr.png',
            code25: 'img/barcodes/img-barcode-code25.png',
            code39: 'img/barcodes/img-barcode-code39.png',
            code128: 'img/barcodes/img-barcode-code128.png'
        },
        canvasWidth:  727,
        canvasHeight: 500
    };

var cardTypeIDs = {
        default:    1,
        magStripe:  2
    };

// default variable text fields and images
var defaultTextFields = [{
        name:   "First Name"
    }, {
        name:   "Last Name"
    }, {
        name:   "Occupation"
    }];

var defaultImageFields = [{
        name:   "Portrait"
    }, {
        name:   "Signature"
    }];

var defaultBarcodeFields = [{
        name:   "Last Name",
        type:   ["barcode","qrcode","track1"]
    },{
        name:   "ID",
        type:   ["barcode","qrcode","track1","track2","track3"]
    },{
        name:   "Website",
        type:   ["qrcode","track1"]
    },{
        name:   "Serial",
        type:   ["track1","track2","track3"]
    }];

var defaultBG = [{
        url:    "img/bg.jpg"
    },{
        url:    "img/bg2.jpg"
    },{
        url:    "img/bg3.jpg"
    }];

var defaultFonts = [{
    name: "EB Garamond",
    url: "//fonts.googleapis.com/css?family=EB+Garamond"
},{
    name: "Allerta Stencil",
    url: "//fonts.googleapis.com/css?family=Allerta+Stencil"
}];
