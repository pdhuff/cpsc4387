#! /bin/bash

read -p "Input GCP project: " project
region="us-central1"


# Move to the correct project
gcloud config set project $project


# Commands to enable the necessary APIs.
read -p "Do you want to enable the necessary APIs at this time? (y/N) " confirmation
while true
do
  case $confirmation in
    [yY]* ) 
      gcloud services enable compute.googleapis.com
      gcloud services enable cloudfunctions.googleapis.com
      gcloud services enable cloudbuild.googleapis.com
      gcloud services enable pubsub.googleapis.com
      gcloud services enable run.googleapis.com
      gcloud services enable cloudscheduler.googleapis.com
      gcloud services enable runtimeconfig.googleapis.com
      break;;

    * )  
      break ;;
  esac
done


# Create a service account for the project
read -p "Do you want to create the service account at this time? (y/N) " confirmation
while true
do
  case $confirmation in
    [yY]* ) 
      gcloud iam service-accounts create myservice --display-name "Service Account for the CPSC 4387-5387 Projects"
      gcloud projects add-iam-policy-binding $project --member=serviceAccount:myservice@"$project".iam.gserviceaccount.com --role='roles/owner'
      gcloud projects add-iam-policy-binding $project --member=serviceAccount:myservice@"$project".iam.gserviceaccount.com --role='roles/pubsub.admin'
      break;;

    * )  
      break ;;
  esac
done


# Create pubsub topics
read -p "Do you want to create the pubsub topics for cloud functions at this time? (y/N) " confirmation
while true
do
  case $confirmation in
    [yY]* ) 
      gcloud pubsub topics create stop-all-servers
      break;;

    * )  
      break ;;
  esac
done


# Create project defaults
read -p "Do you want to set project defaults at this time? (y/N) " confirmation
while true
do
  case $confirmation in
    [yY]* ) 
      gcloud beta runtime-config configs create "myconfig" --description "Project constants for cloud functions and main app"
      gcloud beta runtime-config configs variables set "project" $project --config-name "myconfig"
      gcloud beta runtime-config configs variables set "region" "us-central1" --config-name "myconfig"
      gcloud beta runtime-config configs variables set "zone" "us-central1-a" --config-name "myconfig"
      break;;

    * )  
      break ;;
  esac
done


# Create the maintenance cloud functions
read -p "Do you want to create your stop-servers cloud function at this time? (y/N) " confirmation
while true
do
  case $confirmation in
    [yY]* ) 
      sourcepath="./cloud-functions"
      gcloud functions deploy --quiet function-stop-all-servers \
        --region=$region \
        --memory=256MB \
        --entry-point=cloud_fn_stop_all_servers \
        --runtime=python37 \
        --source=$sourcepath \
        --service-account=myservice@"$project".iam.gserviceaccount.com \
        --timeout=540s \
        --trigger-topic=stop-all-servers
        /
      break;;

    * )  
      break ;;
  esac
done


# Deploy cloud run application
read -p "Do you want to deploy your cloud run application at this time? (y/N) " confirmation
while true
do
  case $confirmation in
    [yY]* ) 
      app="myapp"
      gcloud builds submit "./cloud-run-template" --tag gcr.io/$project/$app
      gcloud run deploy --image gcr.io/$project/$app --memory=1024Mi --platform=managed --region=$region --allow-unauthenticated --service-account=myservice@"$project".iam.gserviceaccount.com
      break;;

    * )  
      break ;;
  esac
done


# Create cloud schedules
read -p "Do you want to create cloud schedules for cloud functions at this time? (y/N) " confirmation
while true
do
  case $confirmation in
    [yY]* ) 
      read -p "What is your timezone? (America/Chicago) " tz
      if ["$tz" == '']
      then
        tz="America/Chicago"
      fi
      gcloud scheduler jobs create pubsub job-stop-all-servers --schedule="0 0 * * *" --topic=stop-all-servers --message-body=Hello!
      break;;

    * )  
      break ;;
  esac
done

