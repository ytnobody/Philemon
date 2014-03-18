use strict;
use Test::More;
use File::Temp 'tempdir';
use File::Spec;
use Proc::Simple;
use Philemon;

subtest overflow => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $worker = Philemon->new(
        target => $tmpdir, 
        max_processes => 4,
        task => sub { 
            my $file = shift;
            sleep 1;
            warn $file;
        },
    );

    my $stderr = File::Spec->catfile($tmpdir, 'stderr.txt');
    my $worker_proc = Proc::Simple->new;
    $worker_proc->signal_on_destroy('KILL');
    $worker_proc->kill_on_destroy(1);
    $worker_proc->redirect_output(undef, $stderr);
    $worker_proc->start(sub { $worker->run } );
    ok $worker_proc->poll;

    sleep 1;

    for my $i (1 .. 4) {
        open my $fh, '>', File::Spec->catfile($tmpdir, $i.'.txt') or die $!;
        print $fh 'foo';
        close $fh;
    }

    {
        open my $fh, '>', File::Spec->catfile($tmpdir, 'foo.txt') or die $!;
        print $fh 'foo';
        close $fh;
    }

    sleep 3;

    $worker_proc->kill;

    my $err;
    {
        open my $fh, '<', $stderr;
        $err = do { local $/; <$fh> };
        close $fh;
    }

    like $err, qr|\[INFO\] start watching $tmpdir in pid [0-9]{3,5}|;
    like $err, qr|\[INFO\] create child process: pid=[0-9]{3,5}|;
    like $err, qr|\[WARN\] Will be retried after a seconds, because number of processes is reached to max_processes|;
    like $err, qr|foo\.txt|;
};

done_testing;
