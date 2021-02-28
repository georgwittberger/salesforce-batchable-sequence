@IsTest
public class sbs_BatchableIterableMock extends sbs_JobSequence implements Database.Batchable<SObject> {
    public static Integer startInvocations = 0;
    public static Integer executeInvocations = 0;
    public static Integer finishInvocations = 0;
    public static Datetime startTime;
    public static Datetime finishTime;
    public static sbs_JobSequence.JobConfig startJobConfiguration;

    public Iterable<SObject> start(Database.BatchableContext context) {
        startInvocations++;
        startTime = Datetime.now();
        startJobConfiguration = getCurrentJobConfiguration();
        return [SELECT Id FROM User];
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
