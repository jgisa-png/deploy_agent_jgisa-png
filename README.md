# Deployment Agent

This Bash script prepares an attendance tracking project, runs an existing project, and archives its session logs.

## Requirements

- Linux with Bash
- Python 3
- zip
- Standard utilities: sed, head, chmod, mkdir, mv and date

Run all commands from the repository root.

The templates directory must contain:

- attendance_checker.py
- assets.csv
- config.json

The script copies the templates into a new project. It does not modify the original Python program or template files.

## Deploy a Project

```bash
bash deploy_agent.sh deploy
```

Running without an argument also starts deployment:

```bash
bash deploy_agent.sh
```

Enter:

1. A project name, such as demo1.
2. The number of students, from 1 to 10.
3. A warning threshold, from 0 to 100.
4. A failure threshold, from 0 to 100.

Press Enter at the threshold prompts to use the defaults:
warning = 75 and failure = 50.

The project name may contain letters, numbers, underscores and hyphens.

The script creates attendance_tracker_demo1 with:

- attendance_checker.py
- Helpers/assets.csv
- Helpers/config.json
- reports/

An existing project path is rejected to prevent overwriting.

This implementation uses roster Option A: it copies the requested number of students from the template, including the CSV header. The template students have four previous sessions, so total_sessions remains 5 for the first new session.

The deployed Python file receives execution permission. The deployed configuration receives permission 600.

Thresholds are updated with sed without reformatting the configuration.

After the folders are created, press Enter to continue deployment. The script then prepares the files and starts the attendance checker.

## Run an Existing Project

```bash
bash deploy_agent.sh run
```

Enter the project suffix, such as demo1.

For each student, enter P for present or A for absent.

The program updates the attendance counters and writes session logs into reports/.

## Archive Logs

```bash
bash deploy_agent.sh archive
```

Enter the project suffix.

The script moves each available log to:

- archives/attendance/attendance_YYYYMMDD_HHMMSS.log
- archives/absent/absent_YYYYMMDD_HHMMSS.log

These directories are inside the selected project.

Each log is handled separately. Missing logs are reported, and existing archive destinations are not overwritten.

## Deployment Interruptions

During project setup, SIGINT and SIGTSTP are handled by a trap.

To demonstrate an interruption:

1. Start deployment with a new project name.
2. Enter the student count and thresholds.
3. Wait for the "Project folders created" prompt.
4. Press Ctrl+C or Ctrl+Z instead of Enter.

The handler creates attendance_tracker_NAME_archive.zip and tests the archive.

The incomplete project is removed only after successful archive creation and validation. If archiving fails or the archive already exists, the incomplete project is preserved.

The traps are disabled before the attendance checker starts.

## Validation

Check Bash syntax with:

```bash
bash -n deploy_agent.sh
```

Verified during development:

- Student selection: three students plus the CSV header.
- Python execution permission and configuration permission 600.
- Threshold changes to warning 80 and failure 40.
- Running an existing project and generating session logs.
- Timestamped archiving of both logs.
- Ctrl+C interruption: valid ZIP and incomplete project removal.

Ctrl+Z verification is still pending.

## Known Limitation

total_sessions is not automatically increased when an existing project is run again. Repeated sessions can therefore produce attendance percentages above 100%.

Before another marking session, the deployed configuration's total_sessions must match the intended session total. This behavior should be checked against the assignment requirements.

## Demonstration Video

Video link: TO BE ADDED# deploy_agent_jgisa-png
