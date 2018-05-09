#!/bin/bash

#2017 by Andreas Keller aka muristan, Kaiserslautern

#Variables
remCertFile=/opt/alfresco-5.1e/mx.muristan-smtp.cert
KEYTOOL=/opt/alfresco-5.1e/java/bin/keytool
KEYSTORE=/opt/alfresco-5.1e/java/lib/security/jssecacerts
KEYSTORE_PASS=password


# Extrahiere den SHA1-Fingerprint aus dem Zertifikat des Servers

# Download des Zertifikats
echo QUIT | openssl s_client -connect mx.muristan.org:587 -starttls smtp >$remCertFile

# Extrahieren des SHA1-Fingerprints
remCertFingerprintLine=$(openssl x509 -fingerprint -noout -in $remCertFile | grep ingerprint)
let=${#remCertFingerprintLine}
#echo $remCertFingerprintLine
#echo $len 
remCertFingerprint=${remCertFingerprintLine:len-59}
echo Remote Certificate Fingerprint: $remCertFingerprint

# Extrahiere den Fingerprint des Zertifikats im Keystore
keystoreFingerprintLine=$($KEYTOOL -storepass ${KEYSTORE_PASS} -list -keystore $KEYSTORE | grep ingerprint)
len=${#keystoreFingerprintLine}
#echo $keystoreFingerprintLine
#echo $len
keystoreFingerprint=${keystoreFingerprintLine:len-59}
echo Keystore Fingerprint: $keystoreFingerprint

# Die beiden Fingerprints vergleichen
if [ "$remCertFingerprint" != "$keystoreFingerprint" ]; 
then
   # Das vom Server geladene Zertifikat ist eine neue Version. Die alte muss aus dem Keystore gelöscht
   # und das neue Zertifikat importeirt werden.
   $KEYTOOL -storepass ${KEYSTORE_PASS} -delete -alias mx.muristan.org -keystore $KEYSTORE
   $KEYTOOL -storepass ${KEYSTORE_PASS} -import -trustcacerts -noprompt -alias mx.muristan.org -file $remCertFile -keystore $KEYSTORE 
   /opt/alfresco-5.1e/alfresco.sh restart    #Neustart von Alfresco nach Austausch des Zertifikats erforderlich 
fi
