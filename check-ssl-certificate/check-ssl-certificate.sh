#!/bin/bash

WAZO_VERSION_FILE="/usr/share/wazo/WAZO-VERSION"
MINIMUM_REQUIRED_VERSION="24.01"

if [ -f "$WAZO_VERSION_FILE" ]; then
    CURRENT_WAZO_VERSION=$(cat "$WAZO_VERSION_FILE")
else
    echo "Le fichier $WAZO_VERSION_FILE n'existe pas. Veuillez entrer la version manuellement:"
    read -r MANUAL_WAZO_VERSION

    while ! is_valid_version "$MANUAL_WAZO_VERSION"; do
        echo "La version saisie '$MANUAL_WAZO_VERSION' ne semble pas être au bon format (xx.xx). Merci de recommencer."
        read -r MANUAL_WAZO_VERSION
    done

    CURRENT_WAZO_VERSION="$MANUAL_WAZO_VERSION"
fi

function is_valid_version() {
    if [[ $1 =~ ^[0-9]{2}\.[0-9]{2}$ ]]; then
        return 0
    else
        return 1
    fi
}

check_expire_date() {

certificate_end_date=$(echo | openssl s_client -connect localhost:443 2> /dev/null | openssl x509 -noout -enddate | cut -d '=' -f2)

whiptail --title "Certificate Information" --msgbox "Votre certificat auto-signé va expirer le : $certificate_end_date. Si cela est déjà arrivé, vous devrez le régénérer." 8 78

generate_new

}

generate_new(){

if (whiptail --title "Generate new self-signed certificate" --yesno "Would you generate a new self-signed certificate ?" 8 78); then
    #agree to generate new certificate
    echo "User selected Yes, exit : $?."
    restart_services
else
    #if no, end script
    echo "User selected No, exit : $?."
    echo "Have a nice day, Wazo team."
fi

}

restart_services(){
if (whiptail --title "Generate new self-signed certificate" --yesno "All services will be restarted, please agree." 8 78); then
    echo "User selected Yes restart services, exit : $?."
    #run Wazo service restart and regenerate self-signed certificate
    run_renew_certificate $?
else
    #if no, and script
    echo "User selected No restart services, exit : $?."
    echo "Have a nice day, Wazo team."
fi
}

run_renew_certificate(){
if [ $1 = 0 ]; then
       {
            echo -e "XXX\n50\nAll Wazo Services stopping. Wait...\nXXX"
            wazo-service stop all
            echo -e "XXX\n100\nAll Wazo Services stopping... Done.\nXXX"
            sleep 0.7
    
    if [ ! -f "$WAZO_VERSION_FILE" ]; then
        echo "Le fichier $WAZO_VERSION_FILE n'existe pas. Veuillez entrer la version manuellement:"
        read -r MANUAL_WAZO_VERSION
    
        while ! is_valid_version "$MANUAL_WAZO_VERSION"; do
            echo "La version saisie '$MANUAL_WAZO_VERSION' ne semble pas être au bon format (xx.xx). Merci de recommencer."
            read -r MANUAL_WAZO_VERSION
        done
    else
        if ("$CURRENT_WAZO_VERSION -le $MINIMUM_REQUIRED_VERSION" || "$MANUAL_WAZO_VERSION -le $MINIMUM_REQUIRED_VERSION")
            echo -e "XXX\n50\nBackup and remove certificates... Wait...\nXXX"
            cp /usr/share/xivo-certs/server.{key,crt} /var/backups
            rm /usr/share/xivo-certs/server.{key,crt}
            echo -e "XXX\n100\nBackup and remove certificates... Done.\nXXX"
            sleep 0.7

            echo -e "XXX\n50\nRegenerate self-signed certificate... Wait...\nXXX"
            dpkg-reconfigure xivo-certs /dev/null 2>&1
            echo -e "XXX\n100\nRegenerate self-signed certificate... Done.\nXXX"
            sleep 0.7
        else
            echo -e "XXX\n50\nBackup and remove certificates... Wait...\nXXX"
            cp /usr/share/wazo-certs/server.{key,crt} /var/backups
            rm /usr/share/wazo-certs/server.{key,crt}
            echo -e "XXX\n100\nBackup and remove certificates... Done.\nXXX"
            sleep 0.7

            echo -e "XXX\n50\nRegenerate self-signed certificate... Wait...\nXXX"
            dpkg-reconfigure wazo-certs /dev/null 2>&1
            echo -e "XXX\n100\nRegenerate self-signed certificate... Done.\nXXX"
            sleep 0.7
        fi
    fi
            echo -e "XXX\n50\nRestart Wazo Services... Wait...\nXXX"
            xivo-update-config /dev/null 2>&1
            wazo-service start all
            echo -e "XXX\n50\nRestart Wazo Services... Done.\nXXX"
            sleep 0.7

        } | whiptail --gauge "Wait Please" 6 60 0

        bye
fi
}

bye(){

certificate_end_date_new=$(echo | openssl s_client -connect localhost:443 2> /dev/null | openssl x509 -noout -enddate | cut -d '=' -f2)

whiptail --title "Congratulation" --msgbox "You have generate new self-signed certificate (New date: $certificate_end_date_new), congratulation. Have a nice day! Wazo Team." 8 78

}
check_expire_date
