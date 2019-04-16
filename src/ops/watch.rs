//! Run a BuildLoop for `shell.nix`, watching for input file changes.
//! Can be used together with `direnv`.
use crate::build_loop::{BuildError, BuildLoop};
use crate::cli::WatchArguments;
use crate::ops::{ok, ExitError, OpResult};
use crate::project::Project;
use crate::roots::Roots;
use std::io::Write;
use std::sync::mpsc::channel;
use std::thread;

/// See the documentation for lorri::cli::Command::Shell for more
/// details.
pub fn main(project: &Project, args: WatchArguments) -> OpResult {
    let (tx, rx) = channel();
    let roots = Roots::new(project.gc_root_path().unwrap(), project.id());

    let mut build_loop = BuildLoop::new(project.expression(), roots);

    if args.once {
        match build_loop.once() {
            Ok(_) => ok(),
            Err(BuildError::Unrecoverable(err)) => ExitError::err(100, format!("{:?}", err)),
            Err(BuildError::Recoverable(exit_failure)) => {
                ExitError::errmsg(exit_failure.log_lines.join("\n"))
            }
        }
    } else {
        let build_thread = {
            thread::spawn(move || {
                build_loop.forever(tx);
            })
        };

        for msg in rx {
            println!("{:#?}", msg);
            let _ = std::io::stdout().flush();
        }

        build_thread.join().unwrap();

        ok()
    }
}
