# Generated by Django 4.0.2 on 2022-04-07 10:02

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("sample", "0023_author_lives_in_book_found_in"),
    ]

    operations = [
        migrations.AddField(
            model_name="cover",
            name="edition",
            field=models.OneToOneField(
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                to="sample.edition",
            ),
        ),
    ]
