extern crate webview;

use std::env;
use std::path::{Path, PathBuf};
use webview::{Content, WebView};

const WIN_SIZE: (i32, i32) = (800, 600);
const RESIZEABLE: bool = false;
const WEB_VIEW_DEBUG: bool = false;
const CURRENT_DIR_READ_ERROR: &str =
	"Failed to get current directory. Check that you have\
	read permission and that the directory has not been deleted";
const PATH_UNICODE_ERROR: &str =
	"Failed to convert path to &str. It is not\
	valid Unicode";
const JS_EVAL_ERROR: &str =
	"Failed to evaluate JavaScript code string because it contained\
	a nul character. This is a bug! Please open an issue";

/// Evaluate a JavaScript code string or panic.
/// # Usage
/// This function is designed to indicate situations
/// where JS code **shall not** contain a nul character.
///
/// If execution fails, the user is informed that there
/// is a bug in the program.
fn eval_expect(wv: &WebView, js: &str) {
	wv.eval(js).expect(JS_EVAL_ERROR)
}

fn build_web_url(filename: &str) -> PathBuf {
	["file://",
	 env::current_dir()
		.expect(CURRENT_DIR_READ_ERROR)
		.to_str()
		.expect(PATH_UNICODE_ERROR),
	 "web",
	 filename].iter().collect()
}

fn path_to_owned_string(path: &Path) -> String {
	String::from(path.to_str().expect(PATH_UNICODE_ERROR))
}

fn main() {
	let idx_path = path_to_owned_string(&build_web_url("index.html"));
	println!("index: {:?}", idx_path);
	
    let wv = WebView::new(
		"Sync",
		Content::Url(idx_path),
		WIN_SIZE.0,
		WIN_SIZE.1,
		RESIZEABLE,
		WEB_VIEW_DEBUG
    ).expect("Failed to create WebView");
    
    /*
    loop {
		wv.loop_once(false);		
	}
	*/
	
	wv.join();
}
