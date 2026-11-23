package io.github.alfatango1.pilot;

import android.os.Bundle;

import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        /* the app's own plugin must be registered before the bridge starts */
        registerPlugin(PilotPrintPlugin.class);
        super.onCreate(savedInstanceState);
    }
}
