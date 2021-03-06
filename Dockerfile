FROM maven:3-jdk-11 AS builder

# Needed on maven image with JDK 14 which is based on Oracle Linux
# RUN yum -y install git

WORKDIR /
RUN git clone --depth 1 https://github.com/ipb-halle/MetFragRelaunched.git
RUN printf '# local database file folder \n\
LocalDatabasesFolderForWeb = /vol/file_databases' > /MetFragRelaunched/MetFragWeb/src/main/webapp/resources/settings.properties
RUN cat /MetFragRelaunched/MetFragWeb/src/main/webapp/resources/settings.properties
RUN mvn -f MetFragRelaunched clean package -pl MetFragLib -pl MetFragWeb -am -DskipTests


FROM tomcat:latest
COPY --from=builder /MetFragRelaunched/MetFragWeb/target/MetFragWeb.war /usr/local/tomcat/webapps/
RUN wget -q -O- https://msbi.ipb-halle.de/~sneumann/file_databases.tgz | tar -C / -xzf -; \
        cd /vol/file_databases; \
        wget -q https://zenodo.org/record/3375500/files/HMDB4_23Aug19.csv; \
        wget -q https://zenodo.org/record/3403530/files/WormJam_10Sept19.csv; \
        wget -q https://zenodo.org/record/3434579/files/YMDB2_17Sept2019.csv; \
        wget -q https://zenodo.org/record/3735703/files/EColiMDB_11Nov2019.csv; \
        wget -q https://zenodo.org/record/3541624/files/Zebrafish_13Nov2019_Beta.csv; \
        wget -q https://zenodo.org/record/3472781/files/CompTox_07March19_WWMetaData.csv; \
        wget -q https://zenodo.org/record/3520106/files/NPAtlas_Aug2019.csv; \
        wget -q https://zenodo.org/record/3548461/files/NORMANSusDat_20Nov2019.csv; \
        wget -q https://zenodo.org/record/3547718/files/COCONUT4MetFrag.csv; \
        wget -q https://zenodo.org/record/3611238/files/PubChemLite_14Jan2020_tier0.csv; \
        wget -q https://zenodo.org/record/3611238/files/PubChemLite_14Jan2020_tier1.csv; \
        wget -q https://zenodo.org/record/3564602/files/BloodExposomeDB_03Dec2019.csv

RUN printf '#!/bin/sh \n\
if [ -f "/resources/settings.properties" ] \n\
then \n\
	jar uvf /usr/local/tomcat/webapps/MetFragWeb.war /resources/settings.properties \n\
fi \n\
if ! [ -z ${WEBPREFIX} ] \n\
then \n\
	mv /usr/local/tomcat/webapps/MetFragWeb.war /usr/local/tomcat/webapps/${WEBPREFIX}.war \n\
fi \n\
catalina.sh run' > /start.sh

CMD [ "sh", "/start.sh" ]
