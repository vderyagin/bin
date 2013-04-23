/* Thanks to Evgeny Chukreev (C) 2005, GNU GPL */
/* See http://akshaal.livejournal.com/58473.html */

/* Modified a little by Bzek .) */

/* Compilation: gcc -L/usr/X11R6/lib -lX11 -o emxkb emxkb.c */

/* Usage:
 *      emxkb 0  # For first group
 *      emxkb 1  # For second group
 *      emxkb 2  # For third group
 */

#include <X11/Xlib.h>
#include <X11/XKBlib.h>
#include <X11/keysym.h>
#include <X11/Xutil.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* For locking a group */
int lock_group (int window_id, int group);

/* For sending a key to Emacs */
int send_key_to_emacs (Display *display, int window_id, int group);


/* Main function */
int
main (int argc, char *argv[]) {

    Display *display;
    XClassHint class_hint;
    Window focus;
    int revert, group;

    /* Check arguments */
    if (argc < 2) {
        fprintf (stderr, "Usage: %s <group>\n", argv[0]);
        return -1;
    }

    /* Parse arguments */
    group = strtol (argv[1], NULL, 0);

    /* Open display */
    display = XOpenDisplay (NULL);

    if (!display) {
        fprintf (stderr, "%s: Can't open display\n", argv[0]);
        return -2;
    }

    /* Get window id */
    if (!XGetInputFocus (display, &focus, &revert)) {
        fprintf (stderr, "%s: Can't get focus\n", argv[0]);
        return -3;
    }

    /* Get WM_CLASS */
    XGetClassHint (display, focus, &class_hint);
    /* printf ("WM_CLASS: %s\n", class_hint.res_name); */

    if (class_hint.res_name != NULL
        && !strncmp (class_hint.res_name, "emacs", strlen("emacs"))) {
        /* Yeah, Emacs! Send a key. */
        if (!send_key_to_emacs (display, focus, group)) {
            fprintf (stderr, "%s: Failed during sending a key to Emacs\n", argv[0]);
            return -4;
        }

        /* Change group to 0 (it should be "us") for Emacs */
        group = 0;
    }

    if (!lock_group (focus, group)) {
        fprintf (stderr, "%s: Failed during locking group\n", argv[0]);
        return -5;
    }

    /* Close display */
    XCloseDisplay (display);

    /* That is all */
    return 0;
}


int
send_key_to_emacs (Display *display, int window_id, int group) {

    XKeyEvent event;

    /* Init event */
    memset (&event, 0, sizeof (event));
    event.window = window_id;
    event.display = display;
    event.root = RootWindow (display, DefaultScreen (display));
    event.state = 0;

    switch (group) {
    case 0:
        event.keycode
            = XKeysymToKeycode (display, XStringToKeysym ("F31"));
        break;
    case 1:
        event.keycode
            = XKeysymToKeycode (display, XStringToKeysym ("F32"));
        break;
    case 2:
        event.keycode
            = XKeysymToKeycode (display, XStringToKeysym ("F33"));
        break;
    default:
        event.keycode
            = XKeysymToKeycode (display, XStringToKeysym ("F31"));
        break;
    }

    /* Send KeyPress event */
    event.type = KeyPress;

    if (!XSendEvent (display, window_id, False, 0, (XEvent *) &event)) {
        fprintf (stderr, "send_key_to_emacs(): Can't send KeyPress event\n");
        return -1;
    }

    /* Send KeyRelease event */
    event.type = KeyRelease;

    if (!XSendEvent (display, window_id, False, 0, (XEvent *) &event)) {
        fprintf (stderr, "send_key_to_emacs(): Can't send KeyRelease event\n");
        return -2;
    }

    XSync (display, False);

    return 1;
}


int
lock_group (int window_id, int group) {

    Display *xkb_display;
    int res;

    /* Open xkb display */
    xkb_display = XkbOpenDisplay (NULL, NULL, NULL, NULL, NULL, NULL);

    if (!xkb_display) {
        fprintf (stderr, "lock_group(): Can't open display\n");
        return -1;
    }

    /* Init XKB */
    res = XkbQueryExtension (xkb_display, NULL, NULL, NULL, NULL, NULL);
    if (!res) {
        fprintf (stderr, "lock_group(): Can't init XKB\n");
        return -2;
    }

    /* Set Focus */
    if (window_id > 0) {
        XSetInputFocus (xkb_display, window_id, RevertToParent, CurrentTime);
        XSync (xkb_display, False);
    }

    /* Lock Group */
    res = XkbLockGroup (xkb_display, XkbUseCoreKbd, abs (group % 4));
    if (!res) {
        fprintf (stderr, "lock_group(): Can't lock group\n");
        return -3;
    }

    XSync (xkb_display, False);

    /* Close xkb display */
    XCloseDisplay (xkb_display);

    return 1;
}
