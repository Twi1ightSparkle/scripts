#!/bin/bash

randomString="$(pwgen -s 12 1)"
tempPng="/tmp/$randomString.png"
inputFile="$1"
inputFileBase="$(basename "$inputFile")"
inputFileTempValue="${inputFileBase##*/}"
inputFileWithoutExtension="${inputFileTempValue%.*}"
inputFileFullPath="$(realpath "$inputFile")"
inputFileDirectory="$(dirname "$inputFileFullPath")"
outputFileFullPath="$inputFileDirectory/$inputFileWithoutExtension.gif"

ffmpeg -i "$inputFileFullPath" -vf palettegen "$tempPng"
ffmpeg -i "$inputFileFullPath" -i "$tempPng" -filter_complex paletteuse -r 10 "$outputFileFullPath"
rm "$tempPng"
