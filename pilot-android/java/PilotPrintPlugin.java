package io.github.alfatango1.pilot;

import android.content.Context;
import android.print.PrintAttributes;
import android.print.PrintDocumentAdapter;
import android.print.PrintManager;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

/**
 * The app's WebView cannot run window.print(), so the commander summary is printed here:
 * the page is loaded into an off-screen WebView and handed to Android's print service,
 * whose dialog also offers "Save as PDF".
 */
@CapacitorPlugin(name = "PilotPrint")
public class PilotPrintPlugin extends Plugin {
    /* kept so the WebView is not collected while the print service reads it */
    private WebView printView;

    @PluginMethod
    public void print(PluginCall call) {
        final String html = call.getString("html");
        final String name = call.getString("name", "Pilot");
        if (html == null || html.isEmpty()) {
            call.reject("No page to print");
            return;
        }
        getActivity().runOnUiThread(() -> {
            try {
                WebView w = new WebView(getActivity());
                w.setWebViewClient(new WebViewClient() {
                    private boolean done = false;

                    @Override
                    public void onPageFinished(WebView view, String url) {
                        if (done) return;
                        done = true;
                        try {
                            PrintManager pm = (PrintManager) getActivity().getSystemService(Context.PRINT_SERVICE);
                            PrintDocumentAdapter adapter = view.createPrintDocumentAdapter(name);
                            PrintAttributes attrs = new PrintAttributes.Builder()
                                    .setMediaSize(PrintAttributes.MediaSize.ISO_A4.asLandscape())
                                    .build();
                            pm.print(name, adapter, attrs);
                            call.resolve();
                        } catch (Exception e) {
                            call.reject(String.valueOf(e.getMessage()));
                        }
                    }
                });
                printView = w;
                w.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null);
            } catch (Exception e) {
                call.reject(String.valueOf(e.getMessage()));
            }
        });
    }
}
