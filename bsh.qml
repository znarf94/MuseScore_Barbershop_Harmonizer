import QtQuick 2.0
import QtQuick.Controls 1.3
import QtQuick.Layouts 1.3
//import QtQuick.Window 2.3
import MuseScore 3.0

MuseScore {
    menuPath: "Plugins.BSH"
    description: "BarberShop Harmonizer"
    version: "1.0"
    pluginType: "dock"
    dockArea:   "right"
    width: 370
    height: 500
    visible: true

    onRun: {
        console.log("panel created");
        next_note();
//      dbg(this);
//        visible = false;
//        for (var p in this) {
//            console.log(p, this[p]);
//        }
    }

//  onScoreStateChanged: function (state) {
//      if (state.selectionChanged) {
//          var el = curScore ? curScore.selection.elements[0] : null;
//          if (el && el.type == Element.NOTE)
//              console.log('note selected :', el.pitch);
//          else
//              console.log('no note selected');
//      }
//  }

    //    TODO: essayer d'intercepter la fermeture du panneau
//    onWidthChanged: {
//        console.log("closed");
//        Qt.quit();
//    }

    property var main_cursor: undefined
    property int current_keysig: 0
    property int tonality: tona_from_ks[current_keysig + 7]
    property bool use_flats: current_keysig <= 0
    property int root: tonality + root_gv.model.get(root_gv.currentIndex).offset
    property var chord: chord_gv.model.get(chord_gv.currentIndex)
    property int lead_note: 60
    property var cursor_text: undefined


    ColumnLayout {
        id: columnLayout
        width: parent.width - 20
        height: parent.height - 20
        anchors.centerIn: parent

        Text {
            text: "Tonality : <b>" + get_note_name(tonality) + " major</b> (using " + (use_flats ? 'flats' : 'sharps') + ')'
        }

        Text {
            text: qsTr("Select root :")
        }

        GridView {
            id: root_gv
            Layout.minimumHeight: 2 * cellHeight
            Layout.fillWidth: true
            cellWidth: parent.width / 7
            cellHeight: 30

            model: ListModel {
                ListElement { name: 'I'; offset: 0 }
                ListElement { name: 'II'; offset: 2 }
                ListElement { name: 'III'; offset: 4 }
                ListElement { name: 'IV'; offset: 5 }
                ListElement { name: 'V'; offset: 7 }
                ListElement { name: 'VI'; offset: 9 }
                ListElement { name: 'VII'; offset: 11 }
                ListElement { name: ''; offset: 6 }
                ListElement { name: ''; offset: 8 }
                ListElement { name: ''; offset: 10 }
                ListElement { name: ''; offset: 11 }
                ListElement { name: ''; offset: 1 }
                ListElement { name: ''; offset: 3 }
                ListElement { name: ''; offset: 5 }
            }

            delegate: Rectangle {
                width: root_gv.cellWidth - 2
                height: root_gv.cellHeight - 2
                color: "transparent"
                border.color: "lightgray"
                border.width: 1
                radius: 4

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (name != '')
                            '<font color="gray">' + name + "</font> <b>"
                                    + get_note_name(tonality + offset) + "</b>"
                        else
                            get_note_name(tonality + offset)
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root_gv.currentIndex = index
                }
            }
            highlight: Rectangle {
                color: "lightsteelblue"
                radius: 4
            }
        }

        Text {
            text: "Select chord :"
        }

        GridView {
            id: chord_gv
            Layout.minimumHeight: 2 * cellHeight
            Layout.fillHeight: false
            Layout.fillWidth: true
            cellWidth: parent.width / 7
            cellHeight: 30

            model: chords_model

            delegate: Rectangle {
                width: chord_gv.cellWidth - 2
                height: chord_gv.cellHeight - 2
                color: "transparent"
                border.color: "lightgray"
                border.width: 1
                radius: 4

                Text {
                    anchors.centerIn: parent
                    text: get_note_name(root) + notation

                    color: (Object.keys(offsets).some(function (k) {
                        return (offsets[k] + root) % 12 === lead_note % 12;
                    })) ? "black" : "lightgray"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: chord_gv.currentIndex = index
                }
            }
            highlight: Rectangle {
                color: "lightsteelblue"
                radius: 4
            }
        }

        Text {
            text: "Choose voicing :"
        }

        GridView {
            id: voicing_gv
            Layout.fillHeight: true
            Layout.fillWidth: true
            cellWidth: 25
            cellHeight: 70

            model: {
                if (typeof chord !== 'undefined') {
                    switch (chord.name) {
                    case 'minor':
                    case 'major':
                        triad_voicings
                        break;
                    case 'augmented':
                        aug_voicings
                        break;
                    case 'diminished':
                        dim_voicings
                        break;
                    case 'seventh':
                    case 'minor seventh':
                    case 'half-diminished seventh':
                        seventh_voicings
                        break;
                    case 'diminished seventh':
                        dim7_voicings
                        break;
                    case 'sixth':
                        sixth_voicings
                        break;
                    case 'ninth':
                        ninth_voicings
                        break;
                    case 'major with added ninth':
                        add9_voicings
                        break;
                    case 'minor with added sixth':
                        madd6_voicings
                        break;
                    case 'major seventh':
                        maj7_voicings
                        break;
                    }
                }
            }

            delegate: Rectangle {
                width: voicing_gv.cellWidth - 2
                height: voicing_gv.cellHeight - 2
                color: "transparent"
                border.color: "lightgray"
                border.width: 1
                radius: 4

                enabled: (typeof chord !== 'undefined')
                         && ((root + chord.offsets[voicing_gv.model.get(index).notes[2]]) % 12 == lead_note % 12)

                Text {
                    anchors.centerIn: parent
                    text: notes[3] + '<br><b>' + notes[2] + '</b><br>' + notes[1] + '<br>' + notes[0]
                    color: enabled ? "black" : "lightgray"
                }

                MouseArea {
                    hoverEnabled: true
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: {
                        voicing_selected(index, mouse.button == Qt.RightButton);
                    }
                    onEntered: {
                        status_bar.text = 'Tenor : ' + function_names[notes[3]]
                                       + '<br>Lead : ' + function_names[notes[2]]
                                       + '<br>Bari : ' + function_names[notes[1]]
                                       + '<br>Bass : ' + function_names[notes[0]]
                                       + '<br><font color="gray">Left-click : closed voicing'
                                       + '<br>Right-click : spread voicing</font>';
                    }
                    onExited: status_bar.text = ''
                }
            }
        }

        Text {
            id: status_bar
            Layout.fillHeight: false
            Layout.fillWidth: true
        }

        Text {
            Layout.fillHeight: false
            Layout.fillWidth: true
            font.pixelSize: 12
         // color: ma.containsMouse ? "steelblue" : "black"

            text: {
                var str = '';

                if (typeof chord !== 'undefined') {
                    str = get_note_name(root) + chord.notation + " (" + chord.name + ")"
                            + '<br>Current note : <font color="#ff00ff">' + get_note_name(lead_note) + '</font>'
                    var interval = (lead_note + 12 - root) % 12;
                    if (interval > 0) {
                        str += ' is a ' + interval_names[interval] + ' above ' + get_note_name(root)
                    } else {
                        str += ' is the root of the chord';
                    }
                }
                str
            }

         // MouseArea {
         //     id: ma
         //     anchors.fill: parent
         //     hoverEnabled: true
         //     onClicked: {
         //         popup.title = get_note_name(root) + chord.notation;
         //         popup.text = "Information about chord";
         //         popup.visible = true;
         //     }
         // }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2

            Button {
                Layout.fillWidth: true
                text: "← Previous"
                onClicked: next_note(true)
            }

            Button {
                Layout.fillWidth: true
                text: "Next →"
                onClicked: next_note()
            }

            Button {
                Layout.fillWidth: true
                iconName: "system-shutdown"
                text: "Close"
                onClicked: {
                    curScore.startCmd();

                    // restore color and remove text
                    var e = main_cursor.element;

                    if (e && (e.type == Element.CHORD)) {
                        e.notes[0].color = "#000000";
                    }

                    removeElement(cursor_text);

                    curScore.endCmd();

                    Qt.quit();
                }
            }

            Button {
                Layout.fillWidth: true
                iconName: "system-help"
                text: "Help"
                onClicked: {
                    popup.title = 'Help';
                    popup.text = "
                    <h3>BarberShop Harmonizer</h3>

                    <p>
                    Tonality is determined automatically from the key signature.
                    </p>

                    <p>
                    Select the root of the chord, then select the chord type.<br/>
                    Click on the desired voicing to apply the change to the accompanying notes (Tenor, Baritone, and Bass).<br/>
                    Right-click on the desired voicing to have a lower Baritone/bass pair.
                    </p>
                    <p>
                    Please click on the 'Close' button to exit the plugin (do not just close the panel)
                    </p>
                    ";
                    popup.visible = true;
                }
            }

         // Button {
         //     text: "Selection"
         //     onClicked: {
         //         var cursor = curScore.newCursor();
         //         cursor.track = 1;
         //         cursor.rewind(Cursor.SELECTION_START);
         //
         //         console.log('cursor tick :', cursor.tick);
         //
         //
         //         console.log(curScore.selection.elements.length, 'elements selected');
         //
         //         var elems = curScore.selection.elements;
         //         for (var i in elems) {
         //             var el = elems[i];
         //             console.log(i, elems[i]);
         //
         //             if (el.type == Element.NOTE) {
         //                 dbg(el);                  // Note
         //                 dbg(el.parent);           // Chord
         //                 dbg(el.parent.parent);    // Segment
         //                 console.log('note :', el.pitch, 'at', el.parent.parent.tick);
         //                 dbg(el.parent.parent.elementAt(1));
         //             }
         //         }
         //     }
         // }
        }
    }

    // ============= Information Popup =============
    Rectangle {
        id: popup
        anchors.fill: parent
        color: "#77000000"
        visible: false

        property string title: ''
        property string text: ''
        property int popup_width: width - 100
        property int popup_height: height - 100

        MouseArea {
            anchors.fill: parent
            onClicked: popup.visible = false
        }

        Column {
            anchors.centerIn: parent
            width: popup.popup_width
            height: popup.popup_height

            Rectangle {
                color: "black"
                width: popup.popup_width
                height: 20

                Text {
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    text: popup.title
                    font.bold: true
                    color: "white"
                }
            }

            Rectangle {
                color: "#ffffff"
                width: popup.popup_width
                height: popup.popup_height - 20

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 10
                    contentHeight: popup_text.contentHeight //contentItem.childrenRect.height
                    contentWidth: popup.popup_width - 20 //contentItem.childrenRect.width
                    clip: true

                    Text {
                        id: popup_text
                        width: popup.popup_width - 20
                        text: popup.text
                        wrapMode: Text.Wrap
                        textFormat: Text.StyledText
                    }
                }
            }
        }
    }

    // =========== Chords =================
    property ListModel chords_model: ListModel {
        Component.onCompleted: {
            append({
                       name: "major",
                       notation: "",
                       offsets: {1: 0, 3: 4, 5: 7}
                   })
            append({
                       name: "seventh",
                       notation: "7",
                       offsets: {1: 0, 3: 4, 5: 7, 7: 10}
                   })
            append({
                       name: "half-diminished seventh",
                       notation: "07",
                       offsets: {1: 0, 3: 3, 5: 6, 7: 10}
                   })
            append({
                       name: "augmented",
                       notation: "+",
                       offsets: {1: 0, 3: 4, 5: 8}
                   })
            append({
                       name: "ninth",
                       notation: "9",
                       offsets: {1: 0, 3: 4, 5: 7, 7: 10, 9: 2}
                   })
            append({
                       name: "sixth",
                       notation: "6",
                       offsets: {1: 0, 3: 4, 5: 7, 6: 9}
                   })
            append({
                       name: "major seventh",
                       notation: "M7",
                       offsets: {1: 0, 3: 4, 5: 7, 7: 11}
                   })
            append({
                       name: "minor",
                       notation: "m",
                       offsets: {1: 0, 3: 3, 5: 7}
                   })
            append({
                       name: "minor seventh",
                       notation: "m7",
                       offsets: {1: 0, 3: 3, 5: 7, 7: 10}
                   })
            append({
                       name: "diminished seventh",
                       notation: "o7",
                       offsets: {1: 0, 3: 3, 5: 6, 7: 9}
                   })
            append({
                       name: "diminished",
                       notation: "o",
                       offsets: {1: 0, 3: 3, 5: 6}
                   })
            append({
                       name: "major with added ninth",
                       notation: "add9",
                       offsets: {1: 0, 3: 4, 5: 7, 9: 2}
                   })
            append({
                       name: "minor with added sixth",
                       notation: "madd6",
                       offsets: {1: 0, 3: 3, 5: 7, 6: 9}
                   })
        }
    }

    // ============= Voicings ===============
    readonly property ListModel seventh_voicings: ListModel {
        ListElement { notes: "5317" }
        ListElement { notes: "5713" }

        ListElement { notes: "1537" }
        ListElement { notes: "1735" }
        ListElement { notes: "5137" }
        ListElement { notes: "5731" }

        ListElement { notes: "1357" }
        ListElement { notes: "1753" }

        ListElement { notes: "1375" }
        ListElement { notes: "1573" }
        ListElement { notes: "5173" }
        ListElement { notes: "5371" }
    }

    readonly property ListModel ninth_voicings: ListModel {
        ListElement { notes: "5793" }
        ListElement { notes: "5397" }
        ListElement { notes: "1793" }

        // Si on veut avoir le ténor une tierce au dessus du lead
        ListElement { notes: "1379" } // ?
    }

    readonly property ListModel sixth_voicings: ListModel {
        ListElement { notes: "1361" }
        ListElement { notes: "1163" }
        ListElement { notes: "1365" }
    }

    readonly property ListModel madd6_voicings: ListModel {
        ListElement { notes: "1563" }
        ListElement { notes: "1356" }
        ListElement { notes: "1653" }
        ListElement { notes: "1635" }
    }

    readonly property ListModel maj7_voicings: ListModel {
        ListElement { notes: "1573" }
        ListElement { notes: "1375" }
    }

    readonly property ListModel add9_voicings: ListModel {
        ListElement { notes: "1593" }
        ListElement { notes: "1395" }
    }

    readonly property ListModel aug_voicings: ListModel {
        ListElement { notes: "1153" }
        ListElement { notes: "1351" }
    }

    readonly property ListModel dim7_voicings: ListModel {
        ListElement { notes: "1375" }
        ListElement { notes: "1735" }
        ListElement { notes: "3715" }
        ListElement { notes: "5713" }
    }

    readonly property ListModel dim_voicings: ListModel {
        ListElement { notes: "1351" }
    }

    readonly property ListModel triad_voicings: ListModel {
        ListElement { notes: "1513" }
        ListElement { notes: "1531" }
        ListElement { notes: "1153" }
        ListElement { notes: "1351" }
        ListElement { notes: "1355" }

        ListElement { notes: "3515" }
        ListElement { notes: "3151" }
        ListElement { notes: "3155" }

        ListElement { notes: "5135" }
        ListElement { notes: "5153" }
        ListElement { notes: "5351" }
    }

    property var note_names: {
        if (use_flats)
            ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B']
        else
            ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
    }

    property var note_tpc: {
        if (use_flats)
            [14, 9, 16, 11, 18, 13, 8, 15, 10, 17, 12, 19]
        else
            [14, 21, 16, 23, 18, 13, 20, 15, 22, 17, 24, 19]
    }

    readonly property var tona_from_ks: [11, 6, 1, 8, 3, 10, 5, 0, 7, 2, 9, 4, 11, 6, 1]

    readonly property var interval_names: [
        'unisson',
        'minor ninth',
        'major ninth',
        'minor third',
        'major third',
        'perfect fourth',
        'tritone',
        'perfect fifth',
        'minor sixth',
        'major sixth', //' / diminished seventh',
        'minor seventh',
        'major seventh',
        'octave',
    ]

    readonly property var function_names: {
        1: 'root',
        3: 'third',
        5: 'fifth',
        6: 'sixth',
        7: 'seventh',
        9: 'ninth',
    }

    function get_note_name(pitch) {
        return note_names[pitch % 12]
    }

    function get_tpc(pitch) {
        return note_tpc[pitch % 12]
    }

    function next_note(reverse) {
        var eof;

        reverse = !!reverse;

        curScore.startCmd();

        if (typeof main_cursor === 'undefined') {
            main_cursor = curScore.newCursor();
            main_cursor.track = 1;
            main_cursor.rewind(Cursor.SCORE_START);

            eof = false;
            while (!eof && main_cursor.element && (main_cursor.element.type != Element.CHORD)) {
                eof = !main_cursor.next();
            }

            if (eof || !main_cursor.element) {
                console.log('rien trouvé sur la voix 1');
                Qt.quit();
                return;
            }
        } else {
            var e = main_cursor.element;
            if (e && (e.type == Element.CHORD)) {
                // Restore color and remove text
                e.notes[0].color = "#000000";
                if (typeof cursor_text !== 'undefined') {
                    removeElement(cursor_text);
                }
            }

            eof = false;
            do {
                eof = reverse ? !main_cursor.prev() : !main_cursor.next();
            } while (!eof && (main_cursor.element.type != Element.CHORD));

            if (eof) {
                main_cursor.rewind(Cursor.SCORE_START);

                while (main_cursor.element && (main_cursor.element.type != Element.CHORD)) {
                    main_cursor.next();
                }
            }
        }

        var e = main_cursor.element;

        if (e && (e.type == Element.CHORD)) {
            var note = e.notes[0];
//          console.log(note, note.pitch);

            if (note.tieBack != null) {
                return next_note(reverse);
            }

            // Apply color and text
            note.color = "#ff00ff";
            lead_note = note.pitch;
            current_keysig = main_cursor.keySignature;

//          console.log('add text');
            cursor_text = newElement(Element.STAFF_TEXT);
            cursor_text.text = get_note_name(lead_note);
            cursor_text.color = "#ff00ff";
            main_cursor.add(cursor_text);
        } else {
            console.log('No element found');
        }

        curScore.endCmd();
    }

    function voicing_selected(index, spread) {
        console.log(spread ? 'spread' : 'closed', 'voicing');
//        for (var k in chord.offsets) {
//            console.log(k, get_note_name(root + chord.offsets[k]));
//        }
//        console.log('---');

        var voicing = voicing_gv.model.get(index);

//        voicing.notes.split('').forEach(function(note){
//            console.log('note', note, get_note_name(root + chord.offsets[note]));
//        });

        console.log('---');

        var tenor_note = root + chord.offsets[voicing.notes[3]];
        while (tenor_note <= lead_note) { tenor_note += 12; }

        var bari_note = root + chord.offsets[voicing.notes[1]];
        while (bari_note < lead_note) { bari_note += 12; }
        if (bari_note >= tenor_note) { bari_note -= 12; }
        if (spread) { bari_note -= 12; }

        var bass_note = root + chord.offsets[voicing.notes[0]];
        while ((bass_note < bari_note) && (bass_note < lead_note)) { bass_note += 12; }
        bass_note -= 12;

        console.log('Tenor : ', tenor_note, get_note_name(tenor_note));
        console.log('Lead  : ', lead_note, get_note_name(lead_note));
        console.log('Bari  : ', bari_note, get_note_name(bari_note));
        console.log('Bass  : ', bass_note, get_note_name(bass_note));

        // ============ Score operation ===============
        curScore.startCmd();

        console.log('currently at tick', main_cursor.tick);

        // Effective note change
        change_pitch(0, tenor_note);
        change_pitch(4, bari_note);
        change_pitch(5, bass_note);

        // Add harmony
        var harmony = get_segment_harmony(main_cursor.segment);
        var chord_name = get_note_name(root) + chord.notation;
        print(harmony);
        print(chord_name);

        if (harmony) {
            // if chord symbol exists, replace it
            harmony.text = chord_name;
        } else {
            // chord symbol does not exist, create it
            harmony = newElement(Element.HARMONY);
            harmony.text = chord_name;
            main_cursor.add(harmony);
        }

     // if (prev_chordName == chord_name) {// && isEqual(prev_full_chord, full_chord)){ //same chord as previous one ... remove text symbol
     //     harmony.text = '';
     // }

        curScore.endCmd();
    }

    function change_pitch(track, pitch) {
        var cur_track = main_cursor.track;
        main_cursor.track = track;
        var elem = main_cursor.element;

        if (elem && (elem.type == Element.CHORD)) {
            var cur_note = elem.notes[0].firstTiedNote;

            console.log('change :', cur_note.pitch, '->', pitch);
            cur_note.pitch = pitch;
            cur_note.tpc = get_tpc(pitch);

            while (cur_note.tieForward != null) {
                console.log('tied note !');
                cur_note = cur_note.tieForward.endNote;
                cur_note.pitch = pitch;
                cur_note.tpc = get_tpc(pitch);
            }
        }

        main_cursor.track = cur_track;
    }

    // Copied from ChordIdentifierSp3_2
    function get_segment_harmony(segment) {
        //if (segment.segmentType != Segment.ChordRest)
        //    return null;
        var aCount = 0;
        var annotation = segment.annotations[aCount];
        while (annotation) {
            if (annotation.type == Element.HARMONY) {
                return annotation;
            }
            annotation = segment.annotations[++aCount];
        }
        return null;
    }


    // =========================================================================================================
    function chord_changed() {
        console.log("chord changed");
    }

    function dbg(element) {
//        console.log(Object.keys(element));
        console.log('==============================================');
        for (var p in element) {
            if (typeof element[p] !== 'undefined') {
                console.log(p, '\t', element[p]);
            }
        }
        console.log('==============================================');
    }

    function add_notes() {
        curScore.startCmd();

        var cursor = curScore.newCursor();
        var notes = [];
        var i_notes = 0;

        // ===== Copie silences ====
//      cursor.filter = Segment.TimeSig;
//      cursor.staffIdx = 0;    // Portée 1
//      cursor.voice = 0;       // Voix 1 !!!
//      cursor.rewind(Cursor.SCORE_START);
//      console.log('filter : ', cursor.filter);

//        var ks = cursor.keySignature;
//        console.log(ks);

//      while (cursor.segment) {
//          var e = cursor.element;
//          if (e) {
//              if (e.type == Element.TIMESIG) {
//                  console.log(e);
//                  console.log(e.timesig);
//                  console.log('current time sig :', e.timesig.numerator, e.timesig.denominator);
//              }
//          }
//          cursor.next();
//      }

        // Copie silences
//      cursor.filter = Segment.ChordRest;
//      cursor.track = 0;
//      cursor.rewind(Cursor.SCORE_START);
//
//      while (cursor.segment) {
//          var e = cursor.element;
//          if (e) {
//              if ((e.type == Element.CHORD) || (e.type == Element.REST)) {
//                  console.log(cursor.tick);
//                  console.log(e.duration.numerator, e.duration.denominator);
//                  cursor.track = 5;
//                  var rest = newElement(Element.REST);
//                  rest.duration = e.duration;
//                  console.log(rest.duration.numerator, rest.duration.denominator);
//                  cursor.add(rest);
//                  cursor.track = 0;
//              }
//          }
//          cursor.next();
//      }
//      curScore.endCmd();
//      return;

        // ====== Lecture notes et silences =======
        cursor.filter = Segment.ChordRest;
        cursor.rewind(Cursor.SCORE_START);
        cursor.staffIdx = 0;    // Portée 1
        cursor.voice = 1;       // Voix 2

        console.log('filter : ', cursor.filter);

        while (cursor.segment) {
            var e = cursor.element;
            //console.log("tick : ", cursor.tick);

            if (e) {
                //console.log("type:", e.name, "at  tick:", e.tick, "color", e.color);
                //dbg(e);

                if (e.type == Element.CHORD) {
                    //console.log("Chord : duration ", e.duration.ticks)

                    notes[i_notes] = ['note', e.duration];
                    i_notes++;

                    //for (var i = 0; i < e.notes.length; i++) {
                    //    console.log("Note : pitch ", e.notes[i].pitch)
                    //}
                 // cursor.setDuration(e.duration.numerator, e.duration.denominator);
                 //
                 // cursor.track = 0; cursor.addNote(72);
                 // cursor.track = 4; cursor.addNote(52);
                 // cursor.track = 5; cursor.addNote(48);
                 // cursor.track = 1;
                } else if (e.type == Element.REST) {
                    //var d = e.duration;
                    //console.log("   duration ", d.ticks);
                    //console.log("   duration " + d.numerator + "/" + d.denominator);

                    //dbg(e);

                    //notes[i_notes] = ['rest', e.duration];
                    notes[i_notes] = ['rest', e];
                    i_notes++;

                //  cursor.track = 0; cursor.add(e.clone());
                //  cursor.track = 4; cursor.add(e.clone());
                //  cursor.track = 5; cursor.add(e.clone());
                //  cursor.track = 1;
                }
            }
            cursor.next();
        }
        console.log(notes);

        [0, 4, 5].forEach(function(track) {
            console.log("track : ", track);

            cursor.track = track;
            cursor.rewind(Cursor.SCORE_START);

            notes.forEach(function(note){
                console.log(cursor.tick, note[0]);

                if (note[0] == 'note') {
                    cursor.setDuration(note[1].numerator, note[1].denominator);
                    cursor.addNote({0: 72, 4: 52, 5: 48}[track]);
                } else {
                    //var rest = newElement(Element.REST);
                    //rest.duration = note[1];
                    var rest = note[1].clone();
                    cursor.add(rest);
//                    cursor.setDuration(note[1].numerator, note[1].denominator);
//                    cursor.addNote(36);
                }
                cursor.next();
            });
        });

        /*
        cursor.rewind(Cursor.SCORE_START);
        cursor.setDuration(1, 4);
        cursor.track = 1;
        cursor.nextMeasure();
        console.log(cursor.staffIdx, cursor.voice, cursor.track, cursor.tick);
        cursor.addNote(38);

        cursor.staffIdx = 1;
        cursor.voice = 1;
        console.log(cursor.staffIdx, cursor.voice, cursor.track, cursor.tick);

        var rest = newElement(Element.REST);
        rest.duration = fraction(1, 4);
        cursor.add(rest);
        console.log(cursor.staffIdx, cursor.voice, cursor.track, cursor.tick);
        cursor.next();
        console.log(cursor.staffIdx, cursor.voice, cursor.track, cursor.tick);
        */

        curScore.endCmd();
    }
}
