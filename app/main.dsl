import "commonReactions/all.dsl";

context
{
    input phone: string;
    input day_of_week: string;
    output day_recall: string="";
    output new_day: string="";
}

external function check_availability(day: string): boolean;

start node root
{
    do
    {
        #connectSafe($phone);
        #waitForSpeech(1000);
        #sayText("Hi, this is Dasha, I'm calling on behalf of Daily Dental. Is this a good time to talk?");
        wait *;
    }
    transitions
    {
        will_call_back: goto will_call_back on #messageHasIntent("no");
        appointment_confirmation: goto appointment_confirmation on #messageHasIntent("yes");
    }
}

node will_call_back
{
    do
    {
        #sayText("No worries, when may we call you back?");
        wait *;
    }
    transitions
    {
        call_bye: goto call_bye on #messageHasData("day_of_week");
    }
}

node call_bye
{
    do
    {
        set $day_recall =  #messageGetData("day_of_week")[0]?.value??"";
        #sayText("Got it, I'll call you back then on " + $day_recall + ". Have a nice day!");
        exit;
    }
}

node appointment_confirmation
{
    do
    {
        #sayText("Great! I see you have an appointment scheduled for " + $day_of_week + ". Will you still be able to come in?");
        wait *;
    }
    transitions
    {
        see_you_then: goto see_you_then on #messageHasIntent("yes");
        new_appt: goto new_appt on #messageHasIntent("new_appt") or #messageHasIntent("no");
    }
}

node see_you_then
{
    do
    {
        #sayText("Awesome, we'll see you then. Bye!");
        exit;
    }
}

node new_appt
{
    do
    {
        #sayText("Got that, would you like to reschedule for another day?");
        wait *;
    }
    transitions
    {
        bye: goto bye on #messageHasIntent("no");
        change_appointment: goto change_appointment on #messageHasIntent("yes");
        day_check: goto day_check on #messageHasData("day_of_week");
    }
}

node bye
{
    do
    {
        #sayText("Alright, I just canceled your appointment. If you decide to reschedule, please give us a call and we'll set a new appointment for you. Have a nice day!");
        #disconnect();
        exit;
    }
}

node change_appointment
{
    do
    {
        #sayText("What day would you like to reschedule your appointment for?");
        wait *;
    }
    transitions
    {
        day_check: goto day_check on #messageHasData("day_of_week");
    }
}

node day_check
{
    do
    {
        set $new_day = #messageGetData("day_of_week")[0]?.value??"";
        var is_available = external check_availability($new_day);
        if (is_available)
        {
            set $day_of_week = $new_day;
            #sayText("Alright, seems like this day is available.");
            goto final_confirm;
        }
        else
        {
            #sayText("It seems like there is no time available this day. Could you choose another day, please?");
            goto change_appointment;
        }
    }
    transitions
    {
        final_confirm: goto final_confirm;
        change_appointment: goto change_appointment;
    }
}

node final_confirm
{
    do
    {
        #sayText("Now, let me just make sure I got it all right. You want to come in for your appointment on " + $day_of_week + " is that right?");
        wait *;
    }
    transitions
    {
        see_you_then: goto see_you_then on #messageHasIntent("yes");
        sorry_repeat: goto sorry_repeat on #messageHasIntent("no");
    }
}

node sorry_repeat
{
    do
    {
        #sayText("Alright, let's try this again");
        goto change_appointment;
    }
    transitions
    {
        change_appointment: goto change_appointment;
    }
}
