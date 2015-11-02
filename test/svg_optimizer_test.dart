library scissors.test.svg_optimizer_test;

import 'package:scissors/src/svg_optimizer.dart';
import 'package:test/test.dart';

main() {
  group('optimizeSvg', () {
    test('trims SVG', () {
      var svg = '''
      <?xml version="1.0" encoding="utf-8"?>
      <!-- Generator: Adobe Illustrator 15.0.0, SVG Export Plug-In  -->
      <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd" [
        <!ENTITY ns_flows "http://ns.adobe.com/Flows/1.0/">
      ]>
      <svg version="1.1"
         xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:a="http://ns.adobe.com/AdobeSVGViewerExtensions/3.0/"
         x="0px" y="0px" width="21px" height="21px" viewBox="0 0 21 21" overflow="visible" enable-background="new 0 0 21 21"
         xml:space="preserve">
        <defs>
        </defs>
        <!-- And this is...
             ... a multiline comment! -->
        <rect x="0" y="0" height="10" width="10" style="stroke:#00ff00; fill: #ff0000"/>
      </svg>
      ''';
      var optimizedSvg =
          '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" '
          'x="0px" y="0px" width="21px" height="21px" viewBox="0 0 21 21" '
          'overflow="visible" enable-background="new 0 0 21 21">'
          '<rect x="0" y="0" height="10" width="10" style="stroke:#00ff00;fill:#ff0000"/>'
          '</svg>';
      expect(optimizeSvg(svg), optimizedSvg);
    });
  });
}
