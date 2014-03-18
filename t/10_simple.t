use strict;
use Test::More;
use File::Temp 'tempdir';
use File::Spec;
use Proc::Simple;
use Philemon;

subtest simple => sub {
    my $tmpdir = tempdir(CLEANUP => 1);
    my $worker = Philemon->new(
        target => $tmpdir, 
        max_processes => 4,
        task => sub { 
            my $file = shift;
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

    {
        open my $fh, '>', File::Spec->catfile($tmpdir, 'foo.txt') or die $!;
        print $fh 'foo';
        close $fh;
    }

    sleep 1;

    $worker_proc->kill;

    my $err;
    {
        open my $fh, '<', $stderr;
        $err = do { local $/; <$fh> };
        close $fh;
    }

    like $err, qr|\[INFO\] start watching $tmpdir in pid [0-9]{3,5}|;
    like $err, qr|\[INFO\] create child process: pid=[0-9]{3,5}|;
};

done_testing;
