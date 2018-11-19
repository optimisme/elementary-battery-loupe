public class MyApp : Gtk.Application {

    private Gtk.ApplicationWindow refWindow;
    private Gtk.Image icon;
    private Gtk.Label labelVendor;
    private Gtk.Label labelModel;
    private Gtk.Label labelSerial;
    private Gtk.Label labelCurrent;
    private Gtk.Label labelFull;
    private Gtk.Label labelDesign;
    private Gtk.Label labelVoltage;
    private Gtk.Label labelPercentage;
    private Gtk.Label labelCapacity;
    private Gtk.ProgressBar barPercentage;
    private Gtk.ProgressBar barCapacity;
    private Gtk.Label labelError;

    public MyApp () {
        Object (
            application_id: "com.github.optimisme.elementary-battery-loupe",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {

        refWindow = new Gtk.ApplicationWindow(this);
        icon = new Gtk.Image();
        labelVendor = new Gtk.Label(null);
        labelModel = new Gtk.Label(null);
        labelSerial = new Gtk.Label(null);
        labelCurrent = new Gtk.Label(null);
        labelFull = new Gtk.Label(null);
        labelDesign = new Gtk.Label(null);
        labelVoltage = new Gtk.Label(null);
        labelPercentage = new Gtk.Label(null);
        labelCapacity = new Gtk.Label(null);
        barPercentage = new Gtk.ProgressBar();
        barCapacity = new Gtk.ProgressBar();
        labelError = new Gtk.Label(null);

        this.initActionQuit();
        this.initBoxes();
        this.fillInfo();

        Timeout.add(30000, () => {
            this.fillInfo();
            return true;
        });
    }

    private void initActionQuit () {

        var quit_action = new SimpleAction("quit", null);
        quit_action.activate.connect (() => {
            if (refWindow != null) {
                refWindow.destroy ();
            }
        });

        add_action (quit_action);
        set_accels_for_action ("app.quit", {"<Control>q"});
    }

    private void initBoxes () {

        var css = new Gtk.CssProvider();
        var boxVertical = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

        boxVertical.margin = 24;
        Gtk.Image icon = new Gtk.Image();
		icon.set_from_icon_name("battery-full-symbolic", Gtk.IconSize.DIALOG);
		boxVertical.pack_start(icon, false);

        try {
            css.load_from_data(" * { color: #f00; font-size: 16px; font-weight: bold; }");
        } catch (GLib.Error e) {
            print ("Error (glib 1): %s\n", e.message);
        }
        labelError.label = _("Error, battery not found");
        labelError.margin = 0;
        labelError.get_style_context().add_provider(css, 0);
        labelError.set_halign(Gtk.Align.CENTER);
        labelError.visible = false;
        boxVertical.pack_start(labelError, false);

        boxVertical.pack_start(this.addEmptyLabel(), false);

        boxVertical.pack_start(this.getInfoBox(_("Vendor"), "", labelVendor), false);
        boxVertical.pack_start(this.getInfoBox(_("Model"), "", labelModel), false);
        boxVertical.pack_start(this.getInfoBox(_("Serial"), "", labelSerial), false);

        boxVertical.pack_start(this.drawLine(), false);

        boxVertical.pack_start(this.getInfoBox(_("Current charge"), "", labelCurrent), false);
        boxVertical.pack_start(this.getInfoBox(_("Full charge capacity"), "", labelFull), false);
        boxVertical.pack_start(this.getInfoBox(_("Design capacity"), "", labelDesign), false);
        boxVertical.pack_start(this.getInfoBox(_("Voltage"), "", labelVoltage), false);

        boxVertical.pack_start(this.addEmptyLabel(), false);

        boxVertical.pack_start(this.addEmptyLabel(), false);
        boxVertical.pack_start(this.getInfoBox(_("Charge"), "", labelPercentage), false);
		boxVertical.pack_start(barPercentage, false);
        barPercentage.set_text ("");
		barPercentage.set_show_text (false);
        barPercentage.set_fraction(0);

        boxVertical.pack_start(this.addEmptyLabel(), false);
        boxVertical.pack_start(this.getInfoBox(_("Capacity"), "", labelCapacity), false);
        boxVertical.pack_start(barCapacity, false);
        barCapacity.set_text ("");
		barCapacity.set_show_text (false);
        barCapacity.set_fraction(0);

        refWindow.title = _("Battery Loupe");
        refWindow.set_default_size(350, 375);
        refWindow.resizable = false;
        refWindow.add(boxVertical);
        refWindow.show_all();
    }

    private void fillInfo () {

        // int cnt = 0;
        string str = "";
        string path = "";
        string[,] data;

        path = this.initBatteryPath();

        if (path == "") {
            labelError.visible = true;
            return;
        } else {
            labelError.visible = false;
        }

        data = this.initBatteryData(path);
/*
        for (cnt = 0; cnt < data.length[0]; cnt = cnt + 1) {
            print("%i < %sxx%s\n", cnt, data[cnt, 0], data[cnt, 1]);
        }
*/
        str = this.getValue(data, "icon-name").replace("'", "");
        if (str != "") {
		    icon.set_from_icon_name(str, Gtk.IconSize.DIALOG);
        }

        str = this.getValue(data, "vendor");
        if (str != "") { labelVendor.label = str; }
        str = this.getValue(data, "model");
        if (str != "") { labelModel.label = str; }
        str = this.getValue(data, "serial");
        if (str != "") { labelSerial.label = str; }

        str = this.getValue(data, "energy");
        if (str != "") { labelCurrent.label = str; }
        str = this.getValue(data, "energy-full");
        if (str != "") { labelFull.label = str; }
        str = this.getValue(data, "energy-full-design");
        if (str != "") { labelDesign.label = str; }
        str = this.getValue(data, "voltage");
        if (str != "") { labelVoltage.label = str; }

        str = this.getValue(data, "percentage");
        if (str != "") {
            labelPercentage.label = str;
            if (str != _("Not available")) {
                barPercentage.set_fraction((float.parse(str.substring(0, str.length - 1))) / 100);
            }
        }

        str = this.getValue(data, "capacity");
        if (str != "") {
            labelCapacity.label = str;
            if (str != _("Not available")) {
                barCapacity.set_fraction((float.parse(str.substring(0, str.length - 1))) / 100);
            }
        }
    }

    private string initBatteryPath () {
        int cnt = 0;
        string[] arr;
        string result = "";
        string stdout;
        string stderr;
        int status;
        try {
            Process.spawn_command_line_sync ("upower --enumerate", out stdout, out stderr, out status);
            arr = stdout.split("\n");
            for (cnt = 0; cnt < arr.length; cnt = cnt + 1) {
                if (arr[cnt].contains("BAT0")) {
                    result = arr[cnt];
                    break;
                }
            }
        } catch (SpawnError e) {
            print ("Error (spawn 1): %s\n", e.message);
        }
        return result;
    }

    private string[,] initBatteryData (string path) {
        int cnt = 0;
        string[] tmp;
        string[] arr;
        string[,] result;
        string stdout;
        string stderr;
        int status;

        try {
            Process.spawn_command_line_sync ("upower -i ".concat(path), out stdout, out stderr, out status);
            arr = stdout.split("\n");
            result = new string[arr.length, 2];
            for (cnt = 0; cnt < arr.length; cnt = cnt + 1) {
                tmp = arr[cnt].replace(" ", "").split(":");
                if (tmp.length == 2) {
                    result[cnt, 0] = tmp[0];
                    result[cnt, 1] = tmp[1];
                }
            }
        } catch (SpawnError e) {
            print ("Error (spawn 2): %s\n", e.message);
        }

        return result;
    }

    private string getValue (string[,] data, string str) {
        int cnt = 0;
        for (cnt = 0; cnt < data.length[0]; cnt = cnt + 1) {
            if (data[cnt, 0] == str) {
                return data[cnt, 1];
            }
        }
        return _("Not available");
    }

    private Gtk.Box getInfoBox (string name, string val, Gtk.Label label1) {

        var css0 = new Gtk.CssProvider();
        var css1 = new Gtk.CssProvider();

        try {
            css0.load_from_data(" * { color: #000; font-size: 16px; font-weight: normal; }");
            css1.load_from_data(" * { color: #000; font-size: 16px; font-weight: bold; }");
        } catch (GLib.Error e) {
            print ("Error (glib 1): %s\n", e.message);
        }

        var label0 = new Gtk.Label(null);
        label0.label = _(name);
        label0.margin = 0;
        label0.get_style_context().add_provider(css0, 0);

        label1.label = val;
        label1.margin = 0;
        label1.get_style_context().add_provider(css1, 0);
        label1.set_halign(Gtk.Align.END);

        var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        box.pack_start(label0, false);
        box.pack_start(label1, true);

        return box;
    }

    private Gtk.Label addEmptyLabel () {
        var label = new Gtk.Label(null);
        label.label = "";
        return label;
    }

    private Gtk.DrawingArea drawLine () {

        var area = new Gtk.DrawingArea();

        area.set_size_request(250, 32);
        area.draw.connect((ctx) => {

            ctx.save();
            ctx.set_source_rgba(0, 0, 0, 0);
            ctx.paint();
            ctx.restore();

            ctx.set_source_rgba(0.75, 0.75, 0.75, 1);

            ctx.move_to(0, 16);
            ctx.line_to(350, 16);
            ctx.stroke();

            return true;
        });

        return area;
    }

    public static int main (string[] args) {
        var app = new MyApp ();
        return app.run (args);
    }
}
