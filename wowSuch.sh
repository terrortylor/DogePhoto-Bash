#! /bin/bash
# Depends on: imagemagick, ghostscript, jot

OFFSET=4

ORIG=$1
NEW=$2
TEXT_SIZE=$3

# Get image width and height
WIDTH=`identify ${ORIG} | cut -d ' ' -f 3 | cut -d 'x' -f 1`
HEIGHT=`identify ${ORIG} | cut -d ' ' -f 3 | cut -d 'x' -f 2`


# arrays for collision detection
declare -a textX
declare -a textY
declare -a textW
declare -a textH

working=${ORIG}
ai=0
for (( i=${OFFSET}; i<=$#; i++ )); do
	text="${!i}"
	# check for collisions
	collision=1
	until [ ${collision} -eq 0 ]; do
		collision=0
		# use of printf to round the value to a decimal
		widthText=$(convert -debug annotate  xc: -pointsize $TEXT_SIZE -annotate 0 "${text}" null: 2>&1 | grep Metrics: | cut -d ';' -f 2,3 | cut -d ' ' -f 3 | sed 's/\;//' | xargs printf "%1.0f")
		heightText=$(convert -debug annotate  xc: -pointsize $TEXT_SIZE -annotate 0 "${text}" null: 2>&1 | grep Metrics: | cut -d ';' -f 2,3 | cut -d ' ' -f 5 | xargs printf "%1.0f")

		leftA=`jot -r 1 100 $((WIDTH - widthText))`
		topA=`jot -r 1 100 $((HEIGHT - heightText))`
		rightA=$(( $leftA + $widthText ))
		bottomA=$(( $topA + $heightText ))
		printf "New Text: X: %s Y: %s X+W: %s Y+H: %s W: %s H: %s Text: %s\n" ${leftA} ${topA} ${rightA} ${bottomA} ${widthText} ${heightText} "${text}"
		if [ ${i} -gt ${OFFSET} ]; then
			for (( j=0; j<${#textX[*]}; j++ )); do
				echo "J is $j"
				leftB=${textX[${j}]}
				topB=${textY[${j}]}
				rightB=$(($leftB + ${textW[${j}]}))
				bottomB=$(($topB + ${textH[${j}]}))
				printf "Checking Text: X: %s Y: %s X+W: %s Y+H: %s W: %s H: %s \n" ${leftB} ${topB} ${rightB} ${bottomB} ${widthText} ${heightText}
				# Check for collisions on existing text
				if [[ $leftB -le $leftA && $leftA -le $rightB ]]; then
					echo "X clash"
					collision=1
					break
				fi
				if [[ $leftB -le $rightA && $rightA -le $rightB ]]; then
					echo "X+W clash"
					collision=1
					break
				fi
				if [[ $topB -le $topA && $topA -le $bottomB ]]; then
					echo "Y clash"
					collision=1
					break
				fi
				if [[ $topB -le $bottomA && $bottomA -le $bottomB ]]; then
					echo "Y+H clash"
					collision=1
					break
				fi
			done
		fi
		if [ ${collision} -eq 0 ]; then
			textX[${ai}]=${leftA}
			textY[${ai}]=${topA}
			textW[${ai}]=${widthText}
			textH[${ai}]=${heightText}
			rCV=`jot -r 1 1 255`
			gCV=`jot -r 1 1 255`
			bCV=`jot -r 1 1 255`
			convert -pointsize ${TEXT_SIZE} -fill "rgb(${rCV},${gCV},${bCV})" -draw "text ${leftA},${topA} \"${text}\" " ${working} ${NEW}
			working=${NEW}

			ai=`expr $ai + 1`
			echo ""
			echo ""
		fi
	done
done
