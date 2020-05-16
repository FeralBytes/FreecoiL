package fhuyakou.godot.plugin.android.helloworld;

import android.app.Activity;
import android.view.View;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;

public class HelloWorldPlugin extends GodotPlugin {

  private static final String HELLO_WORLD = "Hello New World";

  private View helloWorldContainer;

  public HelloWorldPlugin(Godot godot) {
    super(godot);
  }

  @Override
  public String getPluginName() {
    return "HelloWorld";
  }

  @Override
  public List<String> getPluginMethods() {
    return Arrays.asList("hello", "hello2");
  }

  @Override
  public View onMainCreateView(Activity activity) {
    View view = activity.getLayoutInflater().inflate(R.layout.hello_world_view, null);
    helloWorldContainer = view.findViewById(R.id.hello_world_container);
    return view;
  }

  /**
   * Show/hide, print and return "Hello World".
   */
  public String hello() {
    /*if (helloWorldContainer != null) {
      helloWorldContainer.post(new Runnable() {
        @Override
        public void run() {
          if (helloWorldContainer.getVisibility() == View.VISIBLE) {
            helloWorldContainer.setVisibility(View.GONE);
          } else {
            helloWorldContainer.setVisibility(View.VISIBLE);
          }
        }
      });
    }*/

    System.out.println(HELLO_WORLD);
    return HELLO_WORLD;
  }

  public String hello2() {
    System.out.println(HELLO_WORLD);
    return HELLO_WORLD;
  }
}

