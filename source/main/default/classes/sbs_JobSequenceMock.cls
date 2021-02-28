@IsTest
public class sbs_JobSequenceMock extends sbs_JobSequence {
    public sbs_JobSequenceMock(List<sbs_JobSequence.JobConfig> jobConfigurations) {
        super(jobConfigurations);
    }

    public sbs_JobSequence.JobConfig getDelegateCurrentJobConfiguration() {
        return super.getCurrentJobConfiguration();
    }
}
