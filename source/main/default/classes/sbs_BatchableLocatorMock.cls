@IsTest
public class sbs_BatchableLocatorMock extends sbs_JobSequence implements Database.Batchable<SObject> {
    public static Integer startInvocations = 0;
    public static Integer executeInvocations = 0;
    public static Integer finishInvocations = 0;
    public static Datetime startTime;
    public static Datetime finishTime;
    public static sbs_JobSequence.JobConfig startJobConfiguration;

    public Database.QueryLocator start(Database.BatchableContext context) {
        startInvocations++;
        startTime = Datetime.now();
        startJobConfiguration = getCurrentJobConfiguration();
        return Database.getQueryLocator('SELECT Id FROM User');
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        executeInvocations++;
    }

    public void finish(Database.BatchableContext context) {
        finishInvocations++;
        finishTime = Datetime.now();
        executeNextSuccessor();
    }
}
