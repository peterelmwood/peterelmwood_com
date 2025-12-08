"""Management command to generate sample data for testing and development."""

from django.core.management.base import BaseCommand
from django.utils import timezone
from faker import Faker

from core.models import BlogPost, Project


class Command(BaseCommand):
    """Generate sample data for blog posts and projects."""

    help = "Generate sample data for blog posts and projects"

    def add_arguments(self, parser):
        """Add command line arguments."""
        parser.add_argument(
            "--posts",
            type=int,
            default=10,
            help="Number of blog posts to create (default: 10)",
        )
        parser.add_argument(
            "--projects",
            type=int,
            default=5,
            help="Number of projects to create (default: 5)",
        )
        parser.add_argument(
            "--clear",
            action="store_true",
            help="Clear existing data before generating new data",
        )

    def handle(self, *args, **options):
        """Execute the command."""
        fake = Faker()
        posts_count = options["posts"]
        projects_count = options["projects"]
        clear_data = options["clear"]

        if clear_data:
            self.stdout.write("Clearing existing data...")
            BlogPost.objects.all().delete()
            Project.objects.all().delete()
            self.stdout.write(self.style.SUCCESS("Existing data cleared"))

        # Generate blog posts
        self.stdout.write(f"Generating {posts_count} blog posts...")
        for _ in range(posts_count):
            title = fake.sentence(nb_words=6).rstrip(".")
            content_paragraphs = [fake.paragraph(nb_sentences=5) for _ in range(3)]
            content = "\n\n".join(content_paragraphs)

            blog_post = BlogPost.objects.create(
                title=title,
                content=content,
                excerpt=fake.paragraph(nb_sentences=2),
                published=fake.boolean(chance_of_getting_true=70),
                created_at=fake.date_time_between(
                    start_date="-1y",
                    end_date="now",
                    tzinfo=timezone.get_current_timezone(),
                ),
            )

            if blog_post.published:
                blog_post.published_at = blog_post.created_at
                blog_post.save()

        self.stdout.write(self.style.SUCCESS(f"Created {posts_count} blog posts"))

        # Generate projects
        self.stdout.write(f"Generating {projects_count} projects...")
        tech_stacks = [
            "Python, Django, PostgreSQL",
            "React, TypeScript, Node.js",
            "Vue.js, Express, MongoDB",
            "Django REST Framework, React, Docker",
            "FastAPI, PostgreSQL, Redis",
            "Next.js, Tailwind CSS, Vercel",
            "Flask, SQLAlchemy, Celery",
        ]

        for _ in range(projects_count):
            title = fake.catch_phrase()
            description_paragraphs = [fake.paragraph(nb_sentences=3) for _ in range(2)]
            description = "\n\n".join(description_paragraphs)

            Project.objects.create(
                title=title,
                description=description,
                tech_stack=fake.random_element(elements=tech_stacks),
                github_url=(
                    fake.url() if fake.boolean(chance_of_getting_true=80) else ""
                ),
                live_url=(
                    fake.url() if fake.boolean(chance_of_getting_true=60) else ""
                ),
                featured=fake.boolean(chance_of_getting_true=30),
                created_at=fake.date_time_between(
                    start_date="-2y",
                    end_date="now",
                    tzinfo=timezone.get_current_timezone(),
                ),
            )

        self.stdout.write(self.style.SUCCESS(f"Created {projects_count} projects"))
        self.stdout.write(
            self.style.SUCCESS(
                f"Sample data generation complete! Created {posts_count} blog posts "
                f"and {projects_count} projects."
            )
        )
