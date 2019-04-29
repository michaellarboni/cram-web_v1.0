var gulp    = require('gulp'),
    rename  = require('gulp-rename'),
    uglify  = require('gulp-uglify'),
    header  = require('gulp-header'),
    concat  = require('gulp-concat'),
    bower   = require('gulp-bower'),
    install = require('gulp-install');

gulp.task('bower', function () {
    return bower();
});

gulp.task('build', ['install'], function () {
    return;
});

gulp.task('install', ['bower'], function(){
    return gulp.src('public/libs/bootstrap/package.json')
        .pipe(install());
});


gulp.task('default', ['build']);