# shellcheck disable=SC2148
identities_create() {
	# IDENTITES
	Inception_Detect=0

	if [ -z "${BW_Session}" ] || [ "$(echo "${BW_Session}" | wc -c)" -lt 10 ]; then
		tput setaf 4
		echo -e "Lancement du autologin (ne prenez pas en compte les tokens, ils sont gérés automatiquement)."
		tput sgr0
		identities_destroy
		local Bitwarden_Email="<EMAIL_DE_CONNEXION_A_BITWARDEN>"
		local Bitwarden_Server="<URL_DE_L_INSTANCE_BITWARDEN>"
		bw config server "${Bitwarden_Server}"
		# shellcheck disable=SC2155
		export BW_Session="$(bw login "${Bitwarden_Email}" | tee /dev/tty | grep -m1 '==' | cut -d '"' -f 2)"
		Inception_Detect=1
	fi

	local BW_List

	BW_List=$(bw list items --session "$BW_Session")
	if [ "$BW_List" != "" ]; then

		if [ "${Inception_Detect}" != "1" ]; then
			unset BW_Session
		fi

		# shellcheck disable=SC2009
		if [ "$(ps -aux | grep 'sh -c while true; do sleep 10; bw sync -f; done' | grep -cv 'grep')" == "0" ]; then
			nohup sh -c 'while true; do sleep 10; bw sync -f; done' >/dev/null 2>&1 &
		fi

		tput setaf 4
		echo -e "\nBitwarden connecté, mise en place des identités..."
		tput sgr0

		eval "$(ssh-agent)"
		trap 'kill $SSH_AGENT_PID' EXIT

		echo "$BW_List" | jq -r '.[] | select(.name=="identities - configs") | .notes' >"$HOME"/.identities-loaded.sh
		chmod 700 "$HOME"/.identities-loaded.sh
		source "${HOME}"/.identities-loaded.sh

		unset BW_List

	else
		tput setaf 4
		echo "Bitwarden non connecté, les identités n'ont pas été mises en place."
		tput sgr0
	fi
}

identities_destroy() {
	tput setaf 4
	echo "Déconnexion des identités en cours..."
	tput sgr0

	bw logout
	ssh-add -D
	pkill ssh-agent
	unset BW_Session

	tput setaf 4
	echo "Déconnexion des identités terminée"
	tput sgr0
}

identities_create

if [[ -n ${BW_Session} ]]; then
	trap identities_destroy EXIT
fi
