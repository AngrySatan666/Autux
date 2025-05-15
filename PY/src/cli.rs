
use std::env;
use std::process::Command;

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() < 2 {
        println!("Usage:");
        println!("  autux --start");
        println!("  autux --tap X Y");
        println!("  autux --scrsht filename");
        println!("  autux --open_app friendly_app_name");
        println!("  autux --browser_open browser_friendly_name url");
        println!("  autux --browser_close browser_friendly_name");
        return;
    }

    match args[1].as_str() {
        "--start" => {
            Command::new("adb").arg("start-server").status().expect("Failed to start ADB server");
        }
        "--tap" if args.len() == 4 => {
            Command::new("adb")
                .args(["shell", "input", "tap", &args[2], &args[3]])
                .status()
                .expect("Failed to execute tap command");
        }
        "--scrsht" if args.len() == 3 => {
            let filename = &args[2];
            Command::new("adb")
                .args(["shell", "screencap", "-p", filename])
                .status()
                .expect("Failed to take screenshot");
        }
        "--open_app" if args.len() == 3 => {
            let app_name = &args[2];
            Command::new("adb")
                .args(["shell", "monkey", "-p", app_name, "-c", "android.intent.category.LAUNCHER", "1"])
                .status()
                .expect("Failed to open app");
        }
        "--browser_open" if args.len() == 4 => {
            let browser_name = &args[2];
            let url = &args[3];
            Command::new("adb")
                .args(["shell", "am", "start", "-n", browser_name, "-a", "android.intent.action.VIEW", "-d", url])
                .status()
                .expect("Failed to open browser");
        }
        "--browser_close" if args.len() == 3 => {
            let browser_name = &args[2];
            Command::new("adb")
                .args(["shell", "am", "force-stop", browser_name])
                .status()
                .expect("Failed to close browser");
        }
        _ => {
            println!("Invalid command or arguments.");
        }
    }
}
