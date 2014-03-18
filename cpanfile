requires 'perl', '5.008001';
requires 'Linux::Inotify2' => '0';
requires 'Proc::Simple' => '0';
requires 'Log::Minimal' => '0';
requires 'Class::Accessor::Lite' => '0';
requires 'Carp' => '0';
requires 'Guard' => '0';

on 'test' => sub {
    requires 'Test::More' =>  '0.98';
    requires 'Test::Time' => '0';
    requires 'Proc::Simple' => '0';
    requires 'File::Spec' => '0';
};

