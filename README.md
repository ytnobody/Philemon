# NAME

Philemon - Basal worker class for detect a new file

# SYNOPSIS

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



# DESCRIPTION

This is a basal worker class for detect and process a new file.

# OPTIONS

## target

REQUIRED

Path to detect a new file.

## task

REQUIRED

Coderef / Path string to execute when detected a new file.

A full-path for detected file passed as first arg when detected a new file.

## max\_processes

OPTIONAL

Number of limitation for child processes. Default is 8.

## cleanup

OPTIONAL

If it is true value, remove a detected file after processing. Default is undef.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
