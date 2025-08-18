#!/bin/sh

identities_create() {
	# IDENTITES
	Inception_Detect=0

	if [ -z "${BW_Session}" ] || [ "$(echo "${BW_Session}" | wc -c)" -lt 10 ]; then
		Local_Version="2.1.2"
		Latest_Version=$(curl -s "https://gitea.cloudyfy.fr/Siphonight/bw-cli_autologger/src/branch/main/bw_cli_autolog.sh" | grep -m1 "Local_Version" | cut -d ';' -f 2 | cut -d '&' -f 1)
		if [ "${Local_Version}" != "${Latest_Version}" ]; then
			tput setaf 1
			echo "Votre version de l'utilitaire n'est pas à jour."
			echo "Version locale : ${Local_Version} | Dernière version : ${Latest_Version}"
			echo "Récupérez la dernière version sur https://gitea.cloudyfy.fr/Siphonight/bw-cli_autologger ."
		else
			tput setaf 2
			echo "Votre utilitaire est à jour avec la dernière version ! Happy Connect =)"
		fi
		tput setaf 4
		echo "Bitwarden CLI autologger version ${Local_Version}"
		echo "Lancement du autologin (ne prenez pas en compte les tokens, ils sont gérés automatiquement)."
		tput sgr0
		identities_destroy
		Bitwarden_Email="<EMAIL_DE_CONNEXION_A_BITWARDEN>"
		Bitwarden_Server="<URL_DE_L_INSTANCE_BITWARDEN>"
		bw config server "${Bitwarden_Server}"
		# shellcheck disable=SC2155
		export BW_Session="$(bw login "${Bitwarden_Email}" | tee /dev/tty | grep -m1 '==' | cut -d '"' -f 2)"
		Inception_Detect=1
	fi

	BW_List=$(bw list items --session "${BW_Session}")
	if [ "${BW_List}" != "" ]; then

		if [ "${Inception_Detect}" != "1" ]; then
			unset BW_Session
		fi

		# shellcheck disable=SC2009
		if [ "$(ps -ax | grep 'sh -c while true; do sleep 10; bw sync -f; done' | grep -cv 'grep')" = "0" ]; then
			nohup sh -c 'while true; do sleep 10; bw sync -f; done' >/dev/null 2>&1 &
		fi

		tput setaf 4
		echo ""
		echo "Bitwarden connecté, mise en place des identités..."
		tput sgr0

		eval "$(ssh-agent)"

		# shellcheck disable=SC3037
		printf "%s" "${BW_List}" | jq -r '.[] | select(.name=="identities - configs") | .notes' >"${HOME}"/.identities-loaded.sh
		chmod 700 "${HOME}"/.identities-loaded.sh
		# shellcheck disable=SC1091
		. "${HOME}"/.identities-loaded.sh

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

if [ -n "${BW_Session}" ]; then
	trap identities_destroy EXIT
else
	trap "kill $SSH_AGENT_PID && echo test" EXIT
fi
