extern crate webview;

use std::env;
use std::path::{Path, PathBuf};
use webview::{Content, WebView};

const WIN_SIZE: (i32, i32) = (640, 480);
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

fn path_to_owned_string<P: AsRef<Path>>(path: P) -> String {
	format!("file://{}", path.as_ref()
        .to_str()
        .expect(PATH_UNICODE_ERROR))
}

fn build_local_url<F: AsRef<Path>>(filename: F) -> String {
	path_to_owned_string(
        [&env::current_dir().expect(CURRENT_DIR_READ_ERROR),
        Path::new("html"),
        filename.as_ref()].iter().collect::<PathBuf>())
}

fn main() {
	let idx_path = build_local_url("index.html");
	println!("index: {:?}", idx_path);
	
    let wv = WebView::new(
		"Sync",
		Content::Url(idx_path),
		WIN_SIZE.0,
		WIN_SIZE.1,
		RESIZEABLE,
		WEB_VIEW_DEBUG
    ).expect("Failed to create WebView");
    
	eval_expect(&wv, "displayMain()");
    wv.join();
}
