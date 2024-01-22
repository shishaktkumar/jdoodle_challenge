The Problem

Create an AWS autoscaling group based on the load average of the instances (note - it is load average, not CPU utilization). 
Deliverable is a terraform code, which does the following:

1. Create an autoscaling group in AWS with min 2 and max five instances.
2. When the 5 mins load average of the machines reaches 75%, add a new instance.
3. When the 5-minute load average of the machines reaches 50%, remove a machine.
4. Everyday at UTC 12am, refresh all the machines in the group (remove all the old machines and add new machines).
5. Sends email alerts on the scaling and refresh events.


Use any EC2 instance with Ubuntu.



Deliverables:

1. Terraform code - share the GitHub link

2. Demo Video - record a demo video and share the link (Loom or YouTube preferred)
