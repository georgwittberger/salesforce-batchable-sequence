@IsTest
public class sbs_QueueableMock extends sbs_JobSequence implements Queueable {
    public static Integer executeInvocations = 0;
    public static Datetime executeTime;
    public static sbs_JobSequence.JobConfig executeJobConfiguration;

    public void execute(QueueableContext context) {
        executeInvocations++;
        executeTime = Datetime.now();
        executeJobConfiguration = getCurrentJobConfiguration();
        executeNextSuccessor();
    }
}
