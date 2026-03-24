# Overview
This folder will contain a large piece of work I've been building
This is intune proactive remediation scripts, moving away from MECM proactive remediations towards intune based PR scripts is a cloud centric approach & allows for better control over our fleet.
This project saw the review off over 50 MECM configuration items, and carefully deciding which we defintely need to bring over to intune, I've decided our defender checks are the most vital, I'm personally seeing to the movement of 12 defender CI's and modernising the process
I've decided it's best to focus on the following sections:
- Registry keys, intune mgtm agent syncs directly to reg keys to define defender agents behaviour
- Defender behaviour: Ensuring defender is up to date, the reg keys are really taking affect, defender service is actually running etc.
- triggering remediations and logging accurate data for review by security compliance team.
  
# Implementation details
- I've developed a simple check for the reg keys, to ensure updates are being received & all keys are present
- Created multiple functions for checking defender agent is running as expected and scaning for policy drift on our endpoints

I've created remediations to act out the following:
- Trigger an intune sync to receive latest updates/ refresh reg keys.
- Restart defender service
- Update defender agent