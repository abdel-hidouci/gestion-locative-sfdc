/**
 * Classe utilitaire pour gérer le bypass des triggers
 */
public class Triggers {
    private static Set<String> bypassedTriggers = new Set<String>();
    
    public static void bypass(String triggerName) {
        bypassedTriggers.add(triggerName);
    }
    
    public static void clearBypass(String triggerName) {
        bypassedTriggers.remove(triggerName);
    }
    
    public static Boolean isBypassed(String triggerName) {
        return bypassedTriggers.contains(triggerName);
    }
}