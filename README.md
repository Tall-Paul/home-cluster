# home-cluster
Config files etc for provisioning home cluster  
  
NOTE: THIS IS ALL INCREDIBLY INSECURE, DON'T USE ANY OF THIS IN PRODUCTION ETC ETC  
  
/update.sh <-- run this on a cron job, it checks for updates to the repo and, if found deploys them.  
/pods <-- application pods & config.  
/networking <-- calico, kong, metallb config.  
/misc <-- other stuff (currently just the json for the grafana dashboard)  

More info: https://tall-paul.co.uk/2021/03/01/diy-rack-build-pt3-software/

[<img src="https://i.imgur.com/b44RC1b.png">]
