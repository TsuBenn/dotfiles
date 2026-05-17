help me write a python script that convert a file of 5000-ish emojies that looks like:

```😀    Smileys & Emotion    face-smiling    grinning face    cheerful | cheery | face | grin | grinning | happy | laugh | nice | smile | smiling | teeth```


into the following format:
```
{

    "label": "😀",

    "description": "Grinning face <i>Smileys & Emotion</i>", // Notice that "grinning face" got capitalized

    "keywords": ["face-smiling","grinning face","cheerful","cheery", "face" , "grin" , "grinning" , "happy" , "laugh" , "nice" , "smile" , "smiling" , "teeth"],

    "category": "emoji",

    "value": ["bash", "-c", "sleep 0.2 && wtype 😀"],

    "type": "exec",

}
```
