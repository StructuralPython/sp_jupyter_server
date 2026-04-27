# highrise-pdf

## Customizing highrise-pdf

* Fonts
    * Size scale
        * The font size is controlled by a key called 'scale'. The default value is 0.9, which seems to look good. You can change this value but note that extreme variations may "break" the layout or give unexpected results. 
    * Color
        * Specifying the font color only affects the main font color (i.e. non-code). The color of the code is controlled by the code highlight style (See below). 
    * Main font face and code font face
         * Highrise-pdf does NOT have access to your system font files. To use a different font than the default ones included, then you need to "install" the desired font files into the highrise-pdf font directories. Highrise-pdf can load fonts that are physically put into these directories.
         * In addition to putting the font files into the required font directories, you need to specify the font-family name in the .yml file where you are applying the customization. For example, you will see that "Ubuntu" and "CaskaydiaCoveNerdFont" are the included font family names in the _extension.yml file (or the highrise-pdf-all-options.yml, which is a reference file you can use to discover what the range of possible customization values are without having to dig around in the internals of the highrise-pdf extension.
         * To get the full set of font variations (i.e. bold, italic, and bolditalic), you need to pass in the appropriate font files which have those variations. For example, in the main font directory, you will see that there are discrete files for Ubuntu-Regular, Ubuntu-Bold, Ubuntu-Italic, and Ubuntu-BoldItalic. Note, that for any new font you add, you will need to use the same file naming convention of 'FontFamily-Variation.ttf'. The font family name needs to match the font family file nanme and the font family name used _internally_ in the font file.
         * Note that manipulating fonts can be a little fussy so if it does not work at first check that you have all the names figured out and that the files are in the correct location. Check also the font-family name that is specified internally in the font file (which might be slightly different than the font family name used in the file name).
* Code highlight style
    * The code highlight style can be modified to suit your preferences or style however they are all presets. It is not possible to have granular control over code highlighting from highrise-pdf.
    * You can see the list of all acceptable code highlight style names here: https://quarto.org/docs/output-formats/html-code.html#highlighting 
* Paper size
    * You can use any standard paper size either US paper sizes or ISO paper sizes. The exact label you use for the paper size matters however you do not use the full "latex paper size" name in highrise-pdf, e.g. "letter paper" or "a4 paper". With highrise-pdf, you can exclude the "paper" part and just say, "letter" or "a4". Keep that in mind when you review the full list of acceptable paper size values here: https://www.overleaf.com/learn/latex/Page_size_and_margins (at bottom, "References")
* Orientation
    * Orientation (landscape/portrait) is controlled by a key called `'landscape'`. If True, then landscape orientation. Portrait otherwise.
* Margins
    * Margins can be controlled by setting a value (with a unit) for either the top, left, bottom, right, and headsep (which is the distance between the engineering header and the rest of the content).
    * While these values can be set to whatever you want, I recommend against adjusting the top and headsep margins very much (or at all). This is because highrise-pdf uses a combination of latex packages to parameterize the header and content regions so that they can be controlled by the .yml config file and these combination of packages use seemingly conflicting geometry settings. You _can_ adjust the top and headsep margins but be forewarned that large variations from the default values of `top: 30pt` and `headsep: 60pt` can lead to some weird layouts.
    * Left, right, and bottom margins can be controlled as expected without a lot of problem.
    * Note that the left, right, and bottom margins are the margins from the edge of the page and/or the edge of the color bar (if present in a location).
* Color bar
    * Placement location
        * The color bar can be placed on the left, bottom, or right of the page. Due to limitations with the embedded lua-based templating system that quarto uses, the way to specify the location is achieved by using a special key for each location, e.g. `location-bottom: true` sets the color bar to be on the bottom. If you want the color bar to _instead_ be on the right, you change the key from `location-bottom` to `location-right`, so it now becomes `location-right: true`.
        * You cannot place the color bar on the top of the page. 
    * Color
        * Set the colorbar color to any html color code. If you are using an html color code that, coincidentally, does not contain any of the `a`, `b`, `c`, `d`, `e`, `f` hexadecimal digits (e.g. 133143), then you must enclose the color code in quotes, i.e. "133143". 
    * Logo present
        * If you want your logo in the color bar set the `logo: true` (the default). To customize your logo, go into the highrise-pdf "_extension" folder and update the file in the 'logo-dir' to be your logo (which you will also be rename to be 'logo.png').
    * Size
        * This is the width of the color bar. You can specify it in whatever valid latex units you want, e.g. `1.5cm` or `30pt`.
        * When the size of the color bar is set, the logo (if present) will be resized automatically to fit centered within the new colorbar size. It's pretty cool.
* Content box
    * Outline
        * Color
            * 
        * Line weight
        * Corner radius size
    * Background color
    * Inner padding
* Engineering header
    * Content (project id, project name, designer, subject
    * Logo present
    * Width ratio (how much of the page width the header occupies)
    * Left align or right align
    * Top line color
    * Bottom line color

```yaml
title: highrise
author: Me
version: 0.0.1
contributes:
  project:
    project:
      type: default
    format: highrise-pdf
  formats: 
    pdf:
      template: highrise.tex
      toc: false
      number-sections: false
      variables:
        font-paths:
          main: _extensions/highrise/main-font
          code: _extensions/highrise/code-font
        logo-path: _extensions/highrise/logo.png
      fonts:
        main: 
          font-family: Ubuntu
          scale: 0.9
          color: "000000"
        code:
          font-family: CaskaydiaCoveNerdFont
          scale: 0.9
          color: "000000"
          background-color: eeeeee
      highlight-style: a11y
      papersize: letter
      landscape: false
      margins:
        top: 60pt # I do not recommend changing this value
        bottom: 30pt
        left: 30pt
        right: 30pt
        headsep: 60pt

      colorbar:
        logo: true

      contentbox:
        outline:
          color: "eeeeee"
          line_weight: 1pt
          radius: 2pt
        background:
          color: "ffffff"
        padding:
          top: 5mm
          bottom: 5mm
          left: 15mm
          right: 15mm
          splits: 15mm

      engheader:
        project_id: ""
        project_name: ""
        designer: ""
        subject: ""
        page_count: true
        format:
          logo: false
          width_ratio: 0.8
          align-left: false
          line_weight: 1pt
          topline:
            color: "000000"
          bottomline:
            color: "cccccc"
```