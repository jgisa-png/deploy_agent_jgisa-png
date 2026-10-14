#!/bin/bash

action=${1:-deploy}

case "$action" in
    deploy|run|archive)
        ;;
    *)
        echo "Usage: bash deploy_agent.sh [deploy|run|archive]"
        exit 1
        ;;
esac

if [[ "$action" == "deploy" || "$action" == "run" ]]; then
    if command -v python3 > /dev/null 2>&1; then
        echo "Python is available: $(python3 --version)"
    else
        echo "Python3 was not found."
        exit 1
    fi
fi

if [[ "$action" == "deploy" ]]; then
    if command -v zip > /dev/null 2>&1; then
        echo "Zip is available."
    else
        echo "Zip was not found."
        exit 1
    fi
fi

echo "Enter the project name (example: v14):"
read -r project_name

if [[ ! "$project_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Use letters, numbers, underscores or hyphens."
    exit 1
fi

project_dir="attendance_tracker_${project_name}"
echo "Project directory: $project_dir"

if [[ "$action" == "archive" ]]; then
    if [[ ! -d "$project_dir/reports" ]]; then
        echo "Project reports directory was not found."
        exit 1
    fi

    timestamp=$(date +%Y%m%d_%H%M%S)
    archive_status=0

    for log_name in attendance absent; do
        source_log="$project_dir/reports/${log_name}.log"
        archive_dir="$project_dir/archives/${log_name}"
        destination="$archive_dir/${log_name}_${timestamp}.log"

        if [[ ! -f "$source_log" ]]; then
            echo "Missing log: $source_log"
            continue
        fi

        if [[ -e "$destination" ]]; then
            echo "Archive already exists: $destination"
            archive_status=1
            continue
        fi

        if mkdir -p "$archive_dir" &&
           mv "$source_log" "$destination"; then
            echo "Archived: $destination"
        else
            echo "Failed to archive: $source_log"
            archive_status=1
        fi
    done

    exit "$archive_status"
fi

if [[ "$action" == "run" ]]; then
    if [[ ! -f "$project_dir/attendance_checker.py" ]]; then
        echo "Project Python file was not found."
        exit 1
    fi

    (
        cd "$project_dir" || exit 1
        python3 attendance_checker.py
    )
    exit $?
fi

if [[ -e "$project_dir" || -L "$project_dir" ]]; then
    echo "This path already exists. Deployment cancelled."
    exit 1
fi

for template in attendance_checker.py config.json assets.csv; do
    if [[ ! -f "templates/$template" ]]; then
        echo "Missing template: templates/$template"
        exit 1
    fi
done

echo "Enter the number of students (1-10):"
read -r student_count

if [[ ! "$student_count" =~ ^([1-9]|10)$ ]]; then
    echo "Invalid student count. Enter a number from 1 to 10."
    exit 1
fi

echo "Enter warning threshold (0-100, Enter for 75):"
read -r warning
warning=${warning:-75}

echo "Enter failure threshold (0-100, Enter for 50):"
read -r failure
failure=${failure:-50}

if [[ ! "$warning" =~ ^([0-9]|[1-9][0-9]|100)$ ]] ||
   [[ ! "$failure" =~ ^([0-9]|[1-9][0-9]|100)$ ]]; then
    echo "Invalid thresholds. Enter whole numbers from 0 to 100."
    exit 1
fi

handle_interruption() {
    trap '' INT TSTP
    echo "Deployment interrupted. Archiving incomplete project."

    archive_file="${project_dir}_archive.zip"

    if [[ -e "$archive_file" || -L "$archive_file" ]]; then
        echo "Archive already exists. Incomplete project preserved."
        exit 1
    fi

    if zip -r "$archive_file" "$project_dir" &&
       zip -T "$archive_file"; then
        if rm -r -- "$project_dir"; then
            echo "Archive created: $archive_file"
            echo "Incomplete project removed."
        else
            echo "Archive created, but cleanup failed."
        fi
    else
        echo "Archive failed. Incomplete project preserved."
    fi

    exit 1
}

mkdir "$project_dir" || exit 1
trap handle_interruption INT TSTP

mkdir "$project_dir/Helpers" "$project_dir/reports" || exit 1

echo "Project folders created. Press Enter to continue deployment:"
read -r


cp "templates/attendance_checker.py" "$project_dir/" || exit 1
cp "templates/config.json" "$project_dir/Helpers/" || exit 1

head -n "$((student_count + 1))" "templates/assets.csv" \
    > "$project_dir/Helpers/assets.csv" || exit 1

sed -i -E \
    "s/(\"warning\"[[:space:]]*:[[:space:]]*)[0-9]+/\1${warning}/" \
    "$project_dir/Helpers/config.json" || exit 1

sed -i -E \
    "s/(\"failure\"[[:space:]]*:[[:space:]]*)[0-9]+/\1${failure}/" \
    "$project_dir/Helpers/config.json" || exit 1

chmod +x "$project_dir/attendance_checker.py" || exit 1
chmod 600 "$project_dir/Helpers/config.json" || exit 1

echo "File permissions configured."
trap - INT TSTP
echo "Deployment completed. Starting attendance checker."


(
    cd "$project_dir" || exit 1
    python3 attendance_checker.py
)
exit $?
