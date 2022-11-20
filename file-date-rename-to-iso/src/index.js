const fs = require('fs');
const path = require('path');
const { format, parse } = require('date-fns');
const { dirname } = require('path');

// CONFIG
const directory = '/home/twilight/Nextcloud/Camera_uploads';
const logFile = '/home/twilight/temp/file-date-rename-to-iso.log';
// CONFIG

if (!fs.existsSync(directory) || !fs.lstatSync(directory).isDirectory()) {
    return console.log(`Error, ${directory} does not exist or is not a directory`);
}

const live = process.argv[2] === '--live' ? true : false;

/**
 * Recursively get all files in a directory
 * @param {stringString} dirPath    Full path to a directory
 * @param {Array} arrayOfFiles      An array of the full path to all files
 * @returns
 */
const getAllFiles = function (dirPath, arrayOfFiles) {
    const files = fs.readdirSync(dirPath);

    arrayOfFiles = arrayOfFiles || [];

    files.forEach(function (file) {
        const fileFullPath = path.join(dirPath, file);
        if (fs.statSync(fileFullPath).isDirectory()) {
            arrayOfFiles = getAllFiles(fileFullPath, arrayOfFiles);
        } else {
            arrayOfFiles.push(fileFullPath);
        }
    });

    return arrayOfFiles;
};

/**
 * Log something to the log file
 * @param {String} level    Log level. One of d(ebug), e(rror), i(nfo)
 * @param {String} string   The text to log
 */
function log(level, string) {
    const levelShorts = ['d', 'e', 'i'];
    if (!levelShorts.includes(level)) throw new Error(`Invalid level ${level}`);

    const levelLookup = {
        d: 'DEBUG',
        e: 'ERROR',
        i: 'INFO',
    };

    const levelStr = levelLookup[level];
    const timeStamp = format(new Date(), 'yyyy-MM-dd ? HH-mm-ss-SSS').replace(' ? ', 'T');
    const logString = `${timeStamp} ${levelStr} ${string}\n`;

    fs.appendFileSync(logFile, logString);
}

/**
 * Rename a file
 * @param {String} basename         The basename of the existing file
 * @param {String} newBasename      The basename to rename to
 * @param {String} dirName          The full path to the parent directory of the file
 * @returns
 */
function rename(basename, newBasename, dirName) {
    log('i', `Trying to rename "${basename}" to "${newBasename}" in directory "${dirName}"`);

    if (!live) return;

    const file = path.join(dirName, basename);
    const newFile = path.join(dirName, newBasename);

    if (fs.existsSync(newFile)) {
        return log('e', `Target "${newBasename}" already exists. Skipping "${basename}" in directory "${dirName}"`);
    }

    log('i', `Renaming "${basename}" to "${newBasename}" in directory "${dirName}"`);

    try {
        fs.renameSync(file, newFile);
    } catch (error) {
        return log('e', `Error renaming "${basename}" to "${newBasename}" in directory "${dirName}". ${error}`);
    }

    return log('i', `Successfully renamed "${basename}" to "${newBasename}" in directory "${dirName}"`);
}

function main() {
    // Create log directory
    const logDir = path.dirname(logFile);
    if (!fs.existsSync(logDir)) fs.mkdirSync(logDir, { recursive: true });

    const files = getAllFiles(directory);

    files.forEach((file) => {
        const dirName = path.dirname(file);
        const ext = path.extname(file);
        const basename = path.basename(file);
        const fileName = basename.replace(ext, '');
        let id = fileName.match(/( |-)[0-9A-F]{4}$/)[0] || '';
        const orgDateStr = fileName.replace(id, '');
        id = id.replace(' ', '').replace('-', '');

        // 2022-11-20T17-46-51 (this is the target format)
        if (/^\d\d\d\d-\d\d-\d\dT\d\d-\d\d-\d\d$/.test(orgDateStr)) {
            return;
        }

        // 2022-11-20T17-46-51 01AB
        if (/^\d\d\d\d-\d\d-\d\dT\d\d-\d\d-\d\d [0-9A-F]{4}$/.test(fileName)) {
            const newBasename = basename.replace(' ', '-');
            return rename(basename, newBasename, dirName);
        }

        let date;

        try {
            // 22-11-20 17-46-51
            if (/^\d\d-\d\d-\d\d \d\d-\d\d-\d\d$/.test(orgDateStr)) {
                date = parse(orgDateStr, 'yy-MM-dd HH-mm-ss', new Date());
            }

            // 2022-11-20-17-46-51
            else if (/^\d\d\d\d-\d\d-\d\d-\d\d-\d\d-\d\d$/.test(orgDateStr)) {
                date = parse(orgDateStr, 'yyyy-MM-dd-HH-mm-ss', new Date());
            }

            // 22-11-20 5-46-51 pm
            else if (/^\d\d-\d\d-\d\d \d{1,2}-\d\d-\d\d (a|p)m$/.test(orgDateStr)) {
                date = parse(orgDateStr.toUpperCase(), 'yy-MM-dd h-mm-ss aa', new Date());
            }

            // 2022-11-20 5-46-51 pm
            else if (/^\d\d\d\d-\d\d-\d\d \d{1,2}-\d\d-\d\d (a|p)m$/.test(orgDateStr)) {
                date = parse(orgDateStr.toUpperCase(), 'yyyy-MM-dd h-mm-ss aa', new Date());
            }

            // others
            else {
                log('e', `Unable to match "${orgDateStr}"`);
            }
        } catch (error) {
            log('e', `Error parsing "${orgDateStr}"`);
        }

        const newDateStr = format(date, 'yyyy-MM-dd ? HH-mm-ss').replace(' ? ', 'T');
        const newBasename = `${newDateStr}-${id}${ext}`;

        rename(basename, newBasename, dirName);
    });
}

main();
