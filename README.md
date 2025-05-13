## Autux ##
Auto-Usr-Termux : Provides a PyVenv and necessary Termux packages to easily create device automation scripts by using a Wireless Debugging Bride to connect to adb and open a shell. 

### Setup : ###

You must already have setup the main repository with ;
``` bash
termux-change-repo
pkg update && pkg upgrade -y
pk install autux -y
```
and following the UI prompts for the repo selection and intial autux setup prompts.

Not **requried** but it definitely helps to setup storage permissons with ;
``` bash
termux-setup-storage
```
and selecting allow on the following Settings Screen. Then Creating a Directory in your storage that will house all of your scripts (both .sh .py and their assets), and when setting up autux, selecting this folder as your .local/bin, or putting the full path into .config/autux/setting.json. 
We recommend ;
``` sql
|-- storage/documents/scripts/
    |-- bash/
    |-- py/
```
Now everytime a new session is started the entire directory of your selected folder will be copied into .local/bin, added to $PATH and made exectuable. Similary when the PyVenV is setup, you can target another folder that will, upon every activation of the env, will copy the directory of, and place into the env's local/bin, add those to its $PATH, and make executable. You can place python files directly in the bash folder too, this is just where you General Termux scripts will go, and your more complex scripts requring more dependencies can be easily handled by the PyVenv by placing those scripts in the py folder. .sh works just as well here too.
