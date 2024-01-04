#!/bin/bash
# mkvengrip - return english audio and subtitle track IDs for an mkvfile
input_file="$1"

echo "STATUS: Processing input file $1"

mkvinfo_output=$(mkvinfo "$input_file")

line_count=0
section_id=""
section_type=""
section_count=0
eng_audio_tracks=0
audio_tracks=""
subtitle_tracks=""

while IFS= read -r line; do
  if [[ $line == "(MKVInfo) Error:"* ]]; then
    echo "ERROR: cannot open file $1"
    exit 1
  fi
  if [[ $line == "| + Track" ]]; then
    if [[ $section_id != "" && $section_type != "" ]]; then
      if [[ $section_language == "" ]]; then
        echo "ID: $((section_id)), Track Type: $section_type"
        if [[ $section_type == "audio" ]]; then
          if [[ $audio_tracks == "" ]]; then
            audio_tracks="--audio-tracks $((section_id))"
          else
            audio_tracks="$audio_tracks,$((section_id))"
          fi
        elif [[ $section_type == "subtitles" ]]; then
          if [[ $subtitle_tracks == "" ]]; then
            subtitle_tracks="--subtitle-tracks $((section_id))"
          else
            subtitle_tracks="$subtitle_tracks,$((section_id))"
          fi
        fi
      else 
        if [[ $section_type == "audio" ]]; then
          section_count=$((section_count + 1))
        fi
      fi
    fi   
    section_id=""
    section_type=""
    section_language=""
  elif [[ $line =~ "|  + Track number: "* ]]; then
    section_id=$(echo "$line" | sed 's/|  + Track number: \(.*\) (.*/\1/')    
    section_id=$((section_id - 1))
  elif [[ $line == "|  + Track type: "* ]]; then
    section_type=${line#"|  + Track type: "}
  elif [[ $line == "|  + Language: "* ]]; then
    if [[ $line != "|  + Language (IETF BCP 47): en"* ]]; then
      section_language=${line#"|  + Language (IETF BCP 47): "}
    fi
    if [[ $section_type == "audio" ]]; then
      eng_audio_tracks=$((eng_audio_tracks + 1))
    fi
  fi

done <<< "$mkvinfo_output"

if [[ $section_id != "" && $section_type != "" ]]; then
  if [[ $section_language == "" ]]; then
    echo "ID: $((section_id)), Track Type: $section_type"
    if [[ $section_type == "audio" ]]; then
      if [[ $audio_tracks == "" ]]; then
        audio_tracks="--audio-tracks $((section_id))"
      else
        audio_tracks="$audio_tracks,$((section_id))"
      fi
    elif [[ $section_type == "subtitles" ]]; then
      if [[ $subtitle_tracks == "" ]]; then
        subtitle_tracks="--subtitle-tracks $((section_id))"
      else
        subtitle_tracks="$subtitle_tracks,$((section_id))"
      fi
    fi
  else 
    if [[ $section_type == "audio" ]]; then
      section_count=$((section_count + 1))
    fi
  fi
fi

echo "Number foreign language audio tracks: $section_count"
echo "Number english language audio tracks: $eng_audio_tracks"
if [[ $section_count > 0 && $eng_audio_tracks > 0 ]]; then
  if [[ $audio_tracks != "" ]]; then
    echo "$audio_tracks"
  fi
  if [[ $subtitle_tracks != "" ]]; then
    echo "$subtitle_tracks"
  fi
else
  echo "No work for MKVMERGE to do : file has ENG or Foreign audio only"
fi
echo
