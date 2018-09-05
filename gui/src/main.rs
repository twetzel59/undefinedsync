extern crate web_view;

use std::env;
use std::path::{Path, PathBuf};
use web_view::Content;

const WIN_TITLE: &str = "Sync";
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
	
    let _ = web_view::run(
        WIN_TITLE,
        Content::Url(idx_path),
        Some(WIN_SIZE),
        RESIZEABLE,
        false,
        |_| {},
        |_, _, _| {},
        ()
    );
}
