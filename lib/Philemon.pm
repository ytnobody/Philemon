package Philemon;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

use Linux::Inotify2;
use Proc::Simple;
use Log::Minimal;
use Class::Accessor::Lite (
    new => 1,
    ro => [qw[ target task max_processes cleanup ]],
    rw => [qw[ processes ]],
);
use Carp;
use Guard;
use File::Spec;

sub create_process {
    my ($self, $file) = @_;

    my $max_processes = $self->max_processes || 8;

    while (scalar(@{$self->processes}) >= $max_processes) {
        warnf("Will be retried after a seconds, because number of processes is reached to max_processes");
        sleep 1;
        $self->cleanup_finished_childs;
    }

    my $proc = Proc::Simple->new;
    $proc->{__guard} = guard { unlink $file } if $self->cleanup;
    $proc->start($self->task, $file);
    $proc->kill_on_destroy("1");
    $proc->signal_on_destroy("KILL");

    push @{$self->{processes}}, $proc;

    infof("create child process: pid=%s", $proc->pid);

    $proc;
}

sub cleanup_finished_childs {
    my $self = shift;

    $self->processes([grep {$_->poll} @{$self->{processes}}]);
}

sub run {
    my $self = shift;

    $self->processes([]);

    my $target = $self->target;

    my @files = glob( File::Spec->catfile($self->target, '*') );

    my $inotify = Linux::Inotify2->new;
    $inotify->watch($target, IN_CREATE) or critf('could not watch %s : %s', $self->target, $!);

    infof('start watching %s in pid %s', $target, $$);

    if (@files) {
        for my $file (@files) { 
            infof("new file: %s", $file);
            $self->create_process($file);
        }
    }

    while (1) {
        $self->cleanup_finished_childs;

        my @events = $inotify->read;

        if (@events) {
            for my $event (@events) {
                my $file = $event->fullname;
                infof("new file: %s", $file);
                $self->create_process($file);
            }
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Philemon - Basal worker class for detect a new file

=head1 SYNOPSIS

    use Philemon;
    
    my $task = sub {
        my $file = shift;
        some_work( $file );
    };
    
    # or simple command
    my $task = '/path/to/your_script.sh';
    
    my $worker = Philemon->new(
        target        => '/path/to/watching/dir',
        max_processes => 12,
        cleanup       => 1,
        task          => $task,
    );
    
    $worker->run;


=head1 DESCRIPTION

This is a basal worker class for detect and process a new file.

=head1 OPTIONS

=head2 target

REQUIRED

Path to detect a new file.

=head2 task

REQUIRED

Coderef / Path string to execute when detected a new file.

A full-path for detected file passed as first arg when detected a new file.

=head2 max_processes

OPTIONAL

Number of limitation for child processes. Default is 8.

=head2 cleanup

OPTIONAL

If it is true value, remove a detected file after processing. Default is undef.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

